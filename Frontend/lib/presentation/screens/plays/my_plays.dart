import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:snooker_flutter/config/constants/environment.dart';
import 'package:snooker_flutter/entities/play_statistics.dart';
import 'package:snooker_flutter/presentation/widgets/shared/custom_appbar.dart';
import 'package:snooker_flutter/services/http_services/plays_datasource.dart';
import 'package:go_router/go_router.dart';

class MyPlaysScreen extends StatefulWidget {
  static const name = 'my-plays-screen';
  const MyPlaysScreen({super.key});

  @override
  State<MyPlaysScreen> createState() => _MyPlaysScreenState();
}

class _MyPlaysScreenState extends State<MyPlaysScreen> {
  bool _isDataLoaded = false;
  List<Play>? myPlays;

  _loadData() async {
    myPlays = await PlaysService.getInstance().getMyPlays(null);
    setState(() {
      _isDataLoaded = true;
    });
  }

  _saveNetworkImage(String url) async {
    try {
      var response = await Dio().get(url,
          options: Options(responseType: ResponseType.bytes));
      final result = await ImageGallerySaver.saveImage(
          Uint8List.fromList(response.data),
          quality: 60,
          name: "hello");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen guardada en la galería')),
      );
      print(result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar la imagen $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDataLoaded) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Jugadas'),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    final playList = myPlays!;
    return Scaffold(
      appBar: const CustomAppBar(title: 'Jugadas'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio:
                0.5, // Ajusta esto si necesitas cambiar el aspecto
          ),
          itemCount: playList.length,
          itemBuilder: (context, index) {
            final play = playList[index];
            final imageUrl = play.photo != null && play.photo!.isNotEmpty
                ? '${Environment.root}/${play.photo}'
                : 'https://via.placeholder.com/150';
            return GestureDetector(
              onTap: () {
                context.push('/plays/${play.id}/details');
              },
              child: Card(
                elevation: 10.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Stack(
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.download_rounded,
                              color: Colors.white),
                          onPressed: () async {
                            _saveNetworkImage(imageUrl); 
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
