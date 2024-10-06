import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_flutter/presentation/widgets/shared/custom_appbar.dart';
import 'package:snooker_flutter/presentation/widgets/shared/search_bar.dart';
import 'package:snooker_flutter/services/http_services/matches_datasources.dart';
import 'package:snooker_flutter/entities/match.dart';
import 'package:intl/intl.dart';

class ListMatchesScreen extends StatefulWidget {
  static const name = 'list-matches-screen';
  const ListMatchesScreen({super.key});

  @override
  State<ListMatchesScreen> createState() => ListMatchesScreenState();
}

class ListMatchesScreenState extends State<ListMatchesScreen> {
  ScrollController _scrollController = ScrollController();

  bool _isDataLoaded = false;
  String? errorMessage;
  List<Match>? matches;

  int? limit = 20;
  bool _hasMoreMatches = true;
  int _offset = 0;
  int? minFrames;
  int? maxFrames;
  double? minElo;
  double? maxElo;
  DateTime? minDateTime;
  DateTime? maxDateTime;
  String? playerName;
  double? selectedLatitude;
  double? selectedLongitude;

  List<Widget> filterChips = [];
  String? filterError;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _loadMatches();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 20) {
      if (_hasMoreMatches) {
        setState(() {
          _isDataLoaded = true;
        });
        _offset += limit!;
        _loadMatches(offset: _offset);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMatches({int offset = 0}) async {
    try {
      final fetchedMatches = await MatchService.getInstance().getMatches(
        public: true,
        limit: limit,
        offset: offset,
        open: true,
        minFrames: minFrames,
        maxFrames: maxFrames,
        localMinElo: minElo,
        localMaxElo: maxElo,
        minDateTime: minDateTime,
        maxDateTime: maxDateTime,
        latitude: selectedLatitude,
        longitude: selectedLongitude,
      );
      setState(() {
        if (offset == 0) {
          matches =
              fetchedMatches; 
        } else {
          matches?.addAll(fetchedMatches); 
        }
        _isDataLoaded = true;
        errorMessage = null;
        _hasMoreMatches = fetchedMatches.length ==
            limit; 
      });
      setState(() {
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        _isDataLoaded = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $errorMessage')),
      );
    }
  }

  void _updateFilterChips() {
    setState(() {
      filterChips.clear();

      if (minFrames != null) {
        filterChips.add(
          Chip(
            label: Text('Min. Frames: $minFrames'),
            deleteIcon: const Icon(Icons.close),
            onDeleted: () {
              setState(() {
                minFrames = null;
                _updateFilterChips();
                _loadMatches();
              });
            },
          ),
        );
      }

      if (maxFrames != null) {
        filterChips.add(
          Chip(
            label: Text('Max. Frames: $maxFrames'),
            deleteIcon: const Icon(Icons.close),
            onDeleted: () {
              setState(() {
                maxFrames = null;
                _updateFilterChips();
                _loadMatches();
              });
            },
          ),
        );
      }

      if (minElo != null) {
        filterChips.add(
          Chip(
            label: Text('Min. Elo: ${minElo!.toStringAsFixed(1)}'),
            deleteIcon: const Icon(Icons.close),
            onDeleted: () {
              setState(() {
                minElo = null;
                _updateFilterChips();
                _loadMatches();
              });
            },
          ),
        );
      }

      if (maxElo != null) {
        filterChips.add(
          Chip(
            label: Text('Max. Elo: ${maxElo!.toStringAsFixed(1)}'),
            deleteIcon: const Icon(Icons.close),
            onDeleted: () {
              setState(() {
                maxElo = null;
                _updateFilterChips();
                _loadMatches();
              });
            },
          ),
        );
      }

      if (minDateTime != null) {
        filterChips.add(
          Chip(
            label: Text(
                'Fecha Mínima: ${DateFormat('dd/MM/yyyy  kk:mm').format(minDateTime!)}'),
            deleteIcon: const Icon(Icons.close),
            onDeleted: () {
              setState(() {
                minDateTime = null;
                _updateFilterChips();
                _loadMatches();
              });
            },
          ),
        );
      }

      if (maxDateTime != null) {
        filterChips.add(
          Chip(
            label: Text(
                'Fecha Máxima: ${DateFormat('dd/MM/yyyy  kk:mm').format(maxDateTime!)}'),
            deleteIcon: const Icon(Icons.close),
            onDeleted: () {
              setState(() {
                maxDateTime = null;
                _updateFilterChips();
                _loadMatches();
              });
            },
          ),
        );
      }
    });
  }

  void _openFilterPanel() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              height: 500,
              child: Column(
                children: [
                  if (filterError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        filterError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const Text(
                    'Filtros',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
                  ),
                  const SizedBox(height: 16.0),
                  _buildFrameFilter(setModalState),
                  const SizedBox(height: 16.0),
                  _buildEloFilter(setModalState),
                  const SizedBox(height: 16.0),
                  _buildDateTimeFilter('Fecha y Hora Mínima',
                      (DateTime? value) {
                    setModalState(() {
                      minDateTime = value;
                    });
                  }),
                  const SizedBox(height: 16.0),
                  _buildDateTimeFilter('Fecha y Hora Máxima',
                      (DateTime? value) {
                    setModalState(() {
                      maxDateTime = value;
                    });
                  }),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      if (_validateFilters()) {
                        Navigator.pop(context);
                        _offset = 0;
                        _updateFilterChips();
                        _loadMatches();
                      }
                    },
                    child: const Text('Aplicar Filtros'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _validateFilters() {
    bool isValid = true;
    setState(() {
      filterError = null;

      if (minFrames != null && maxFrames != null && minFrames! > maxFrames!) {
        filterError =
            'El número mínimo de frames no puede ser mayor que el máximo.';
        isValid = false;
      }

      if (minElo != null && maxElo != null && minElo! > maxElo!) {
        filterError = 'El Elo mínimo no puede ser mayor que el máximo.';
        isValid = false;
      }

      if (minDateTime != null &&
          maxDateTime != null &&
          minDateTime!.isAfter(maxDateTime!)) {
        filterError =
            'La fecha mínima no puede ser posterior a la fecha máxima.';
        isValid = false;
      }
    });

    return isValid;
  }

  Widget _buildFrameFilter(StateSetter setModalState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DropdownButton<int>(
          hint: const Text('Mínimo Frames'),
          value: minFrames,
          items: List.generate(11, (index) => index).map((value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text(value.toString()),
            );
          }).toList(),
          onChanged: (value) {
            setModalState(() {
              minFrames = value;
            });
          },
        ),
        DropdownButton<int>(
          hint: const Text('Máximo Frames'),
          value: maxFrames,
          items: List.generate(11, (index) => index).map((value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text(value.toString()),
            );
          }).toList(),
          onChanged: (value) {
            setModalState(() {
              maxFrames = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildEloFilter(StateSetter setModalState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DropdownButton<double>(
          hint: const Text('Mínimo Elo'),
          value: minElo,
          items: List.generate(10, (index) => (index + 1) * 0.5).map((value) {
            return DropdownMenuItem<double>(
              value: value,
              child: Text(value.toString()),
            );
          }).toList(),
          onChanged: (value) {
            setModalState(() {
              minElo = value;
            });
          },
        ),
        DropdownButton<double>(
          hint: const Text('Máximo Elo'),
          value: maxElo,
          items: List.generate(10, (index) => (index + 1) * 0.5).map((value) {
            return DropdownMenuItem<double>(
              value: value,
              child: Text(value.toString()),
            );
          }).toList(),
          onChanged: (value) {
            setModalState(() {
              maxElo = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateTimeFilter(String label, Function(DateTime?) onChanged) {
    return GestureDetector(
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        if (pickedDate != null) {
          TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (pickedTime != null) {
            final DateTime dateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            onChanged(dateTime);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16.0),
            ),
            Text(
              (label.contains('Mínima') ? minDateTime : maxDateTime) != null
                  ? DateFormat('dd/MM/yyyy  kk:mm').format(
                      label.contains('Mínima') ? minDateTime! : maxDateTime!)
                  : 'Seleccionar',
              style: const TextStyle(fontSize: 16.0, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, Match match) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          context.push('/matches/${match.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage:
                        NetworkImage(match.local?.profilePhoto ?? ''),
                    radius: 30.0,
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.matchDatetime ?? 'Fecha no disponible',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(match.location ?? 'Ubicación no disponible'),
                        const SizedBox(height: 8.0),
                        Text('Frames: ${match.frames ?? 0}'),
                        const SizedBox(height: 8.0),
                        Text(
                            'Rival: ${match.local?.name ?? ''} | ${match.local?.elo ?? ''}'),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 0.0,
                child: Text(
                  match.distance ?? '',
                  style: const TextStyle(
                    fontSize: 19.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDataLoaded) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Partidas'),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: const CustomAppBar(title: 'Partidas'),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 10.0),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () {
                        _openFilterPanel();
                      },
                    ),
                    Expanded(
                      child: SearchMapBar(
                        onLocationSelected: (location) {
                          setState(() {
                            selectedLatitude = location?.lat;
                            selectedLongitude = location?.lng;
                          });
                          _offset = 0;
                          _loadMatches();
                        },
                      ),
                    ),
                  ],
                ),
                if (filterChips.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: filterChips.map((chip) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: chip,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      _offset = 0;
                      await _loadMatches(offset: _offset);
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount:
                          (matches?.length ?? 0) + (_hasMoreMatches ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= (matches?.length ?? 0)) {
                          // Return a loading indicator at the end of the list
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final match = matches?[index];
                        return _buildMatchCard(context, match!);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
