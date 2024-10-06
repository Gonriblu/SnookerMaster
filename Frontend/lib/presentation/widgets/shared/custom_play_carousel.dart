import 'dart:async';
import 'package:flutter/material.dart';
import 'package:snooker_flutter/config/constants/environment.dart';
import 'package:go_router/go_router.dart';

class CustomPlayCarousel extends StatelessWidget {
  final List<dynamic> itemsList;
  final double height;
  final String title;
  final double defaultWidth = 150;

  const CustomPlayCarousel({
    super.key,
    required this.itemsList,
    this.height = 200,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: () {
                context.push('/my_plays');
              },
              child: const Text('Ver Todos'),
            ),
          ],
        ),
        const SizedBox(height: 20.0),

        // Verificamos si la lista está vacía
        if (itemsList.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No hay jugadas creadas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          )
        else
          SizedBox(
            height: height,
            child: FutureBuilder<List<Size>>(
              future: _loadAllImages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar las imágenes'));
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: itemsList.length,
                  itemBuilder: (context, index) {
                    final item = itemsList[index];
                    final imageUrl = item.photo != null && item.photo!.isNotEmpty
                        ? '${Environment.root}/${item.photo}'
                        : 'https://via.placeholder.com/150';

                    final double aspectRatio = snapshot.data![index].width / snapshot.data![index].height;

                    return GestureDetector(
                      onTap: () {
                        context.push('/plays/${item.id}/details');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: AspectRatio(
                          aspectRatio: aspectRatio,
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Future<List<Size>> _loadAllImages() async {
    List<Future<Size>> futures = itemsList.map((item) {
      final imageUrl = item.photo != null && item.photo!.isNotEmpty
          ? '${Environment.root}/${item.photo}'
          : 'https://via.placeholder.com/150';
      return _getImageSize(imageUrl);
    }).toList();

    return Future.wait(futures);
  }

  Future<Size> _getImageSize(String imageUrl) async {
    final Image image = Image.network(imageUrl);
    final Completer<Size> completer = Completer<Size>();
    final ImageStream stream = image.image.resolve(ImageConfiguration.empty);
    stream.addListener(
      ImageStreamListener(
        (ImageInfo info, bool _) => completer.complete(Size(info.image.width.toDouble(), info.image.height.toDouble())),
      ),
    );
    return completer.future;
  }
}
