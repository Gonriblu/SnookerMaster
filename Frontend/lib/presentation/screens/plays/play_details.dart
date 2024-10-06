import 'package:flutter/material.dart';
import 'package:snooker_flutter/config/constants/environment.dart';
import 'package:snooker_flutter/entities/play_statistics.dart';
import 'package:snooker_flutter/presentation/screens/image_full_screen.dart';
import 'package:snooker_flutter/presentation/widgets/shared/custom_appbar.dart';
import 'package:snooker_flutter/services/http_services/plays_datasource.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:gallery_saver_plus/gallery_saver.dart';

class PlayDetailsScreen extends StatefulWidget {
  static const name = 'play-details-screen';
  const PlayDetailsScreen({super.key, required this.id});
  final String id;

  @override
  State<PlayDetailsScreen> createState() => _PlayDetailsScreenState();
}

class _PlayDetailsScreenState extends State<PlayDetailsScreen> {
  bool _isDataLoaded = false;
  bool _isVideoLoading = false;
  bool _isDownloading = false;
  final bool _isLoadingVideo = false; // Para el indicador de carga en el botón
  Play? play;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  Future<String?> _getLocalFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/${widget.id}.mp4';
  }

  Future<bool> _isVideoCached() async {
    final filePath = await _getLocalFilePath();
    final file = File(filePath!);
    return file.exists();
  }

  Future<void> _clearVideoCache() async {
    final filePath = await _getLocalFilePath();
    final file = File(filePath!);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> _loadData() async {
    play = await PlaysService.getInstance().getPlayDetails(widget.id);

    setState(() {
      _isDataLoaded = true;
    });
  }

  void _initializeVideoPlayer() async {
    setState(() {
      _isVideoLoading = true;
    });

    final videoUrl = '${Environment.root}/plays/get_video/${widget.id}';
    final filePath = await _getLocalFilePath();

    try {
      // Descargar el video y almacenarlo en el caché local
      final response = await http.get(Uri.parse(videoUrl));
      final file = File(filePath!);
      await file.writeAsBytes(response.bodyBytes);

      // Inicializar el reproductor con el archivo descargado
      _videoPlayerController = VideoPlayerController.file(File(filePath));

      await _videoPlayerController?.initialize();
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: false,
          looping: false,
          allowPlaybackSpeedChanging: true,
        );
        _isVideoLoading = false;
      });

      _videoPlayerController?.addListener(() {
        if (_videoPlayerController!.value.position ==
            _videoPlayerController!.value.duration) {
          setState(() {
            _chewieController?.pause();
          });
        }
      });
    } catch (error) {
      setState(() {
        _isVideoLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar el video: $error')),
      );
    }
  }

  Future<void> _downloadVideo() async {
    setState(() {
      _isDownloading = true;
    });

    final videoUrl = '${Environment.root}/plays/get_video/${widget.id}';
    final filePath = await _getLocalFilePath();

    try {
      final response = await http.get(Uri.parse(videoUrl));
      final file = File(filePath!);
      await file.writeAsBytes(response.bodyBytes);
      setState(() {
        _isDownloading = false;
      });
      // Guardar el video en la galería
      GallerySaver.saveVideo(filePath).then((bool? success) {
        if (success != null && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video guardado en la galería')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Error al guardar el video en la galería')),
          );
        }
      });
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al descargar el video')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _clearVideoCache(); // Limpiar el caché de video al entrar a la pantalla
    _loadData();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _clearVideoCache(); // Limpiar el caché de video al salir de la pantalla
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDataLoaded) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Estadísticas'),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (play == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Estadísticas'),
        body: Center(
          child: Text('Error al cargar la jugada.'),
        ),
      );
    }

    final imageUrl = play!.photo != null && play!.photo!.isNotEmpty
        ? '${Environment.root}/${play!.photo}'
        : 'https://via.placeholder.com/150';

    return Scaffold(
      appBar: const CustomAppBar(title: 'Estadísticas'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FullScreenImage(imageUrl: imageUrl),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      height: 200,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),

              // Estadísticas con mejor presentación
              _buildStatisticsCard('Ángulo',
                  play!.angle != null ? '${play!.angle}\u00B0' : 'Sin datos'),
              _buildStatisticsCard(
                'Distancia a la bola objetivo',
                play!.distance != null
                    ? '${play!.distance!.toStringAsFixed(2)} metros'
                    : 'Sin datos',
              ),
              _buildStatisticsCard(
                  'Éxito', play!.success == true ? 'Sí' : 'No'),
              _buildStatisticsCard(
                  'Color de la bola embocada', play!.secondColorBall ?? 'Sin datos'),
              _buildStatisticsCard(
                  'Tronera elegida', play!.pocket ?? 'Sin datos'),
              const SizedBox(height: 16.0),

              if (play!.video != null) ...[
                Center(
                  child: ElevatedButton(
                    onPressed: _initializeVideoPlayer,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 12.0),
                      textStyle: const TextStyle(fontSize: 18.0),
                    ),
                    child: _isLoadingVideo
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text('Ver video'),
                  ),
                ),
                const SizedBox(height: 16.0),
                Center(
                  child: _isDownloading
                      ? const CircularProgressIndicator() // Indicador de descarga
                      : ElevatedButton.icon(
                          onPressed: _downloadVideo,
                          icon: const Icon(Icons.download),
                          label: const Text('Descargar video'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 12.0),
                            textStyle: const TextStyle(fontSize: 18.0),
                          ),
                        ),
                ),
              ],

              if (_isVideoLoading) ...[
                const SizedBox(height: 16.0),
                const Center(
                  child: CircularProgressIndicator(),
                ),
              ],

              if (_chewieController != null && !_isVideoLoading) ...[
                const SizedBox(height: 16.0),
                AspectRatio(
                  aspectRatio: _videoPlayerController!.value.aspectRatio,
                  child: Chewie(
                    controller: _chewieController!,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Método para construir las estadísticas de manera más bonita
  Widget _buildStatisticsCard(String label, String value) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
