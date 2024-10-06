import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrCodeScanner extends StatelessWidget {
  QrCodeScanner({
    required this.setResult,
    super.key,
  });

  final Function setResult;
  final MobileScannerController controller = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: controller,
      onDetect: (BarcodeCapture capture) async {
        final List<Barcode> barcodes = capture.barcodes;
        final barcode = barcodes.first;

        if (barcode.rawValue != null) {
          // Procesar el código QR y devolver el resultado
          setResult(barcode.rawValue);

          // Detén el escáner QR, pero no cierres la pantalla de escaneo de inmediato
          await controller.stop();
          controller.dispose();
        }
      },
    );
  }
}
