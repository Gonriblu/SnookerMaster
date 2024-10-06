import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomGridSection extends StatelessWidget {
  final String title;
  final List<String> imgList;
  final String url;

  const CustomGridSection({
    super.key,
    required this.title,
    required this.imgList,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10.0),
        Flexible(
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: imgList.length + 1,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              if (index == 0) {
                return GestureDetector(
                  onTap: () {
                    // Acción para crear nueva partida o imagen
                  },
                  child: Card(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.add, size: 50, color: Colors.black),
                    ),
                  ),
                );
              } else {
                return GestureDetector(
                  onTap: (){
                    context.push(url);
                  },
                  child: Card(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.asset(
                            imgList[index - 1],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 5.0,
                              horizontal: 4.0,
                            ),
                            child: const Text(
                              'Nombre partida',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
