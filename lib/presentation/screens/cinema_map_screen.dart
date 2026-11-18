import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../data/services/device_location_service.dart';
import '../../data/repositories/open_street_map_cinema_repository.dart';
import '../../domain/models/cinema_theater.dart';
import '../../domain/models/movie.dart';
import '../localization/app_strings.dart';
import '../state/nearby_cinemas_controller.dart';

class CinemaMapScreen extends ConsumerStatefulWidget {
  const CinemaMapScreen({super.key, required this.movie});

  final Movie movie;

  @override
  ConsumerState<CinemaMapScreen> createState() => _CinemaMapScreenState();
}

class _CinemaMapScreenState extends ConsumerState<CinemaMapScreen> {
  MapLibreMapController? _mapController;
  String? _selectedCinemaId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final search = ref.watch(nearbyCinemasProvider);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Кинотеатры рядом'.tr(context)),
            Text(
              widget.movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: search.when(
        data: (result) => result == null
            ? _locationIntro(colors)
            : result.cinemas.isEmpty
            ? _emptyState(colors)
            : _mapAndCinemaList(result, colors),
        loading: () => _progressState(colors),
        error: (error, _) => _errorState(error, colors),
      ),
    );
  }

  Widget _locationIntro(ColorScheme colors) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_movies_outlined,
              size: 48,
              color: colors.secondary,
            ),
            const SizedBox(height: 20),
            Text(
              'Кинотеатры для просмотра этого фильма'.tr(context),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              'Точные координаты передаются публичному Overpass API для поиска и не сохраняются приложением.'
                  .tr(context),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant, height: 1.55),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _searchNearby,
              icon: const Icon(Icons.my_location),
              label: Text('Найти кинотеатры рядом'.tr(context)),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _progressState(ColorScheme colors) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 18),
          Text('Ищем кинотеатры…'.tr(context)),
          const SizedBox(height: 8),
          Text(
            'Выполняется запрос к публичному Overpass API. Координаты не сохраняются приложением.'
                .tr(context),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    ),
  );

  Widget _errorState(Object error, ColorScheme colors) {
    final message = switch (error) {
      LocationAccessException(:final problem) => switch (problem) {
        LocationProblem.servicesDisabled =>
          'Включи службы геолокации на устройстве и повтори попытку.'.tr(
            context,
          ),
        LocationProblem.permissionDenied =>
          'Доступ к местоположению запрещён. Разреши его для этого сайта и повтори попытку.'
              .tr(context),
        LocationProblem.permissionDeniedForever =>
          'Разреши доступ к местоположению в браузере или настройках устройства и повтори попытку.'
              .tr(context),
        LocationProblem.positionTimeout =>
          'Не удалось быстро получить геопозицию. Проверь настройки браузера и повтори попытку.'
              .tr(context),
      },
      CinemaSearchUnavailableException() =>
        'Сервис карты временно перегружен. Подожди немного и повтори поиск.'.tr(
          context,
        ),
      _ =>
        'Не удалось загрузить кинотеатры. Проверь подключение и повтори попытку.'
            .tr(context),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_disabled_outlined,
              size: 42,
              color: colors.error,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _searchNearby,
              icon: const Icon(Icons.refresh),
              label: Text('Повторить поиск'.tr(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(ColorScheme colors) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.theaters_outlined, size: 42, color: colors.secondary),
          const SizedBox(height: 16),
          Text('Кинотеатры поблизости не найдены.'.tr(context)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _searchNearby,
            icon: const Icon(Icons.refresh),
            label: Text('Повторить поиск'.tr(context)),
          ),
        ],
      ),
    ),
  );

  Widget _mapAndCinemaList(NearbyCinemaSearch result, ColorScheme colors) {
    final map = Stack(
      fit: StackFit.expand,
      children: [
        MapLibreMap(
          styleString: jsonEncode(_openStreetMapStyle),
          initialCameraPosition: CameraPosition(
            target: LatLng(result.center.latitude, result.center.longitude),
            zoom: 13,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            controller.onCircleTapped.add(_onCircleTapped);
          },
          onStyleLoadedCallback: () => _addMapMarkers(result),
          myLocationEnabled: false,
          compassEnabled: true,
          attributionButtonPosition: AttributionButtonPosition.bottomLeft,
          logoViewPosition: LogoViewPosition.bottomLeft,
        ),
        if (_selectedCinemaId != null) _selectedCinemaCard(result, colors),
        Positioned(
          right: 10,
          bottom: 10,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: .92),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              child: Text(
                '© OpenStreetMap contributors',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 780) {
          return Row(
            children: [
              Expanded(child: map),
              SizedBox(width: 360, child: _cinemaList(result, colors)),
            ],
          );
        }
        final mapHeight = (constraints.maxHeight * .52).clamp(250.0, 480.0);
        return Column(
          children: [
            SizedBox(height: mapHeight, child: map),
            Expanded(child: _cinemaList(result, colors)),
          ],
        );
      },
    );
  }

  Widget _selectedCinemaCard(NearbyCinemaSearch result, ColorScheme colors) {
    CinemaTheater? cinema;
    for (final item in result.cinemas) {
      if (item.id == _selectedCinemaId) cinema = item;
    }
    if (cinema == null) return const SizedBox.shrink();
    return Positioned(
      left: 16,
      top: 16,
      right: 16,
      child: Card(
        color: colors.surface.withValues(alpha: .96),
        child: ListTile(
          leading: Icon(Icons.theaters_rounded, color: colors.secondary),
          title: Text(
            cinema.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            cinema.address ?? 'Адрес не указан'.tr(context),
            maxLines: 2,
          ),
          trailing: IconButton(
            tooltip: 'Закрыть'.tr(context),
            onPressed: () => setState(() => _selectedCinemaId = null),
            icon: const Icon(Icons.close),
          ),
        ),
      ),
    );
  }

  Future<void> _addMapMarkers(NearbyCinemaSearch result) async {
    final controller = _mapController;
    if (controller == null) return;
    try {
      await controller.clearCircles();
      await controller.addCircles(
        [
          for (final cinema in result.cinemas)
            CircleOptions(
              geometry: LatLng(
                cinema.location.latitude,
                cinema.location.longitude,
              ),
              circleRadius: 9,
              circleColor: '#A88DBB',
              circleStrokeColor: '#F4EFE8',
              circleStrokeWidth: 2,
            ),
        ],
        [
          for (final cinema in result.cinemas) {'cinemaId': cinema.id},
        ],
      );
      await controller.addCircle(
        CircleOptions(
          geometry: LatLng(result.center.latitude, result.center.longitude),
          circleRadius: 8,
          circleColor: '#91A88B',
          circleStrokeColor: '#F4EFE8',
          circleStrokeWidth: 3,
        ),
        const {'currentLocation': true},
      );
    } catch (_) {
      // Map tiles can still be browsed if an annotation could not be rendered.
    }
  }

  void _onCircleTapped(Circle circle) {
    final id = circle.data?['cinemaId'];
    if (id is String) setState(() => _selectedCinemaId = id);
  }

  Widget _cinemaList(NearbyCinemaSearch result, ColorScheme colors) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Кинотеатры рядом'.tr(context),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Повторить поиск'.tr(context),
              onPressed: _searchNearby,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          itemCount: result.cinemas.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final cinema = result.cinemas[index];
            final selected = cinema.id == _selectedCinemaId;
            final distance = Geolocator.distanceBetween(
              result.center.latitude,
              result.center.longitude,
              cinema.location.latitude,
              cinema.location.longitude,
            );
            final distanceLabel = distance >= 1000
                ? '${(distance / 1000).toStringAsFixed(1)} ${'км'.tr(context)}'
                : '${distance.round()} ${'м'.tr(context)}';
            return Material(
              color: selected
                  ? colors.secondaryContainer
                  : colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                leading: Icon(Icons.theaters_outlined, color: colors.secondary),
                title: Text(
                  cinema.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${cinema.address ?? 'Адрес не указан'.tr(context)}\n$distanceLabel',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: cinema.address != null,
                onTap: () => _focusCinema(cinema),
              ),
            );
          },
        ),
      ),
    ],
  );

  Future<void> _focusCinema(CinemaTheater cinema) async {
    setState(() => _selectedCinemaId = cinema.id);
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(cinema.location.latitude, cinema.location.longitude),
        16,
      ),
    );
  }

  Future<void> _searchNearby() =>
      ref.read(nearbyCinemasProvider.notifier).loadNearby();
}

const _openStreetMapStyle = {
  'version': 8,
  'sources': {
    'openstreetmap': {
      'type': 'raster',
      'tiles': ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
      'tileSize': 256,
      'attribution': '© OpenStreetMap contributors',
    },
  },
  'layers': [
    {'id': 'openstreetmap-tiles', 'type': 'raster', 'source': 'openstreetmap'},
  ],
};
