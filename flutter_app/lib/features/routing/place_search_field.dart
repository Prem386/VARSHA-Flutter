import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/place.dart';
import '../../models/route.dart';
import '../../services/places/places_service.dart';

/// Place search card and autocomplete input matching React PlaceSearchInput.tsx.
/// Uses an anchored floating [OverlayEntry] in compact mode to ensure suggestions never
/// cause layout thrashing or vertical displacement of surrounding controls.
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
  final bool isCompact;
  final bool autofocus;

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
    this.isCompact = false,
    this.autofocus = false,
  });

  @override
  State<PlaceSearchField> createState() => _PlaceSearchFieldState();
}

class _PlaceSearchFieldState extends State<PlaceSearchField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  late final PlacesService _placesService;

  OverlayEntry? _overlayEntry;
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
      if (_focusNode.hasFocus && _controller.text.isEmpty) {
        _showDropdown = true;
        _fallbackSuggestions = popularLandmarks
            .map((l) => l.toSuggestion())
            .toList();
        _isCuratedFallback = true;
      } else if (!_focusNode.hasFocus) {
        _showDropdown = false;
      }
      _updateOverlay();
      if (mounted) setState(() {});
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
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateOverlay() {
    if (!mounted || !widget.isCompact) return;

    if (_showDropdown) {
      final overlay = Overlay.maybeOf(context);
      if (overlay == null) return;

      if (_overlayEntry == null) {
        _overlayEntry = _createOverlayEntry();
        overlay.insert(_overlayEntry!);
      } else {
        _overlayEntry!.markNeedsBuild();
      }
    } else {
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        final renderBox = this.context.findRenderObject() as RenderBox?;
        final size = renderBox?.size ?? const Size(300, 44);

        final activeSuggestions = _remoteSuggestions.isNotEmpty
            ? _remoteSuggestions
            : _fallbackSuggestions;

        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 4),
            child: Material(
              elevation: 8,
              shadowColor: AppColors.shadowDark,
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: _buildSuggestionsList(activeSuggestions),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    final clean = query.trim();

    if (clean.length < 2) {
      setState(() {
        _isLoading = false;
        _remoteSuggestions = [];
        if (clean.isEmpty && _focusNode.hasFocus) {
          _fallbackSuggestions = popularLandmarks
              .map((l) => l.toSuggestion())
              .toList();
          _isCuratedFallback = true;
          _showDropdown = true;
        } else {
          _showDropdown = false;
        }
      });
      _updateOverlay();
      return;
    }

    setState(() {
      _isLoading = true;
      _showDropdown = true;
    });
    _updateOverlay();

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      try {
        final res = await _placesService.searchPlaces(clean);
        if (mounted) {
          setState(() {
            _isLoading = false;
            _remoteSuggestions = res.results;
            _isCuratedFallback = false;
          });
          _updateOverlay();
        }
      } catch (err) {
        if (mounted) {
          // Fallback to local curated Navi Mumbai landmarks
          final localMatches = searchCuratedLandmarks(clean, limit: 4);
          setState(() {
            _isLoading = false;
            _remoteSuggestions = [];
            _fallbackSuggestions = localMatches
                .map((l) => l.toSuggestion())
                .toList();
            _isCuratedFallback = true;
          });
          _updateOverlay();
        }
      }
    });
  }

  void _selectPlace(PlaceSuggestion place) {
    _removeOverlay();
    _controller.text = place.name;
    _focusNode.unfocus();
    setState(() => _showDropdown = false);

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
  }

  void _clearInput() {
    _removeOverlay();
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

    if (widget.isCompact) {
      return _buildCompact(context, activeSuggestions);
    }
    return _buildStandard(context, activeSuggestions);
  }

  Widget _buildCompact(
    BuildContext context,
    List<PlaceSuggestion> activeSuggestions,
  ) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            // Endpoint Indicator Badge
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _badgeColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                widget.tagLetter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Endpoint Label
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: widget.isActiveTarget
                    ? AppColors.amberText
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            // Input TextField
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                onChanged: _onQueryChanged,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.placeholder,
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            // Loading Indicator
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            // Clear action
            if (_controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                tooltip: 'Clear ${widget.label.toLowerCase()}',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: _clearInput,
              ),
            // Pick on Map action
            IconButton(
              icon: Icon(
                Icons.my_location,
                size: 16,
                color: widget.isActiveTarget
                    ? AppColors.amberText
                    : AppColors.textMuted,
              ),
              tooltip: widget.isActiveTarget ? 'Target Active' : 'Pick on Map',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () {
                _removeOverlay();
                _focusNode.unfocus();
                widget.onActivateTarget();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandard(
    BuildContext context,
    List<PlaceSuggestion> activeSuggestions,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isActiveTarget
              ? AppColors.amber
              : AppColors.borderSubtle,
          width: widget.isActiveTarget ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _badgeColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      widget.tagLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                icon: Icon(
                  Icons.my_location,
                  size: 14,
                  color: widget.isActiveTarget
                      ? AppColors.amberText
                      : AppColors.routePrimary,
                ),
                label: Text(
                  widget.isActiveTarget ? 'Selecting on Map' : 'Pick on Map',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.isActiveTarget
                        ? AppColors.amberText
                        : AppColors.routePrimary,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: widget.isActiveTarget
                      ? AppColors.amber.withAlpha(26)
                      : AppColors.background,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  _removeOverlay();
                  _focusNode.unfocus();
                  widget.onActivateTarget();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: widget.autofocus,
                    onChanged: _onQueryChanged,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
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
          if (_showDropdown) ...[
            const SizedBox(height: 8),
            Material(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: _buildSuggestionsList(activeSuggestions),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(List<PlaceSuggestion> activeSuggestions) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        // Quick Action: Choose on Map
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 0,
          ),
          leading: const Icon(
            Icons.my_location,
            size: 16,
            color: AppColors.amberText,
          ),
          title: Text(
            'Choose ${widget.label.toLowerCase()} on map',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.amberText,
            ),
          ),
          onTap: () {
            _removeOverlay();
            _focusNode.unfocus();
            widget.onActivateTarget();
          },
        ),

        // Quick Action: Current Location (if Origin)
        if (widget.endpointType == RouteEndpointType.origin)
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 0,
            ),
            leading: const Icon(
              Icons.near_me,
              size: 16,
              color: AppColors.routePrimary,
            ),
            title: const Text(
              'Navi Mumbai Pilot Center',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.routePrimary,
              ),
            ),
            subtitle: const Text(
              'Nerul • Geographic Center',
              style: TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
            onTap: () {
              _selectPlace(
                const PlaceSuggestion(
                  id: 'navi-mumbai-center',
                  name: 'Navi Mumbai Pilot Center',
                  formattedAddress: 'Nerul • Transit Hub',
                  latitude: 19.0330,
                  longitude: 73.0297,
                  source: 'curated',
                ),
              );
            },
          ),

        const Divider(height: 1, color: AppColors.borderSubtle),

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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 0,
              ),
              leading: const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.textMuted,
              ),
              title: Text(
                place.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                place.formattedAddress,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
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
                    color: place.source == 'curated'
                        ? AppColors.amberText
                        : AppColors.routePrimary,
                  ),
                ),
              ),
              onTap: () => _selectPlace(place),
            );
          }),
      ],
    );
  }
}
