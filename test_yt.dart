import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  try {
    var manifest = await yt.videos.streamsClient.getManifest("https://youtu.be/YPpsppxS0s8");
    var audio = manifest.audioOnly.withHighestBitrate();
    print("Success: ${audio.url}");
  } catch (e) {
    print("Error: $e");
  } finally {
    yt.close();
  }
}
