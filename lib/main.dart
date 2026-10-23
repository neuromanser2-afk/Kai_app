import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:geolocator/geolocator.dart';

String currentLang = "ar";
Map<String, Map<String, String>> trMap = {
  "ar": {"online":"متصل الآن","today":"اليوم","yesterday":"أمس","message":"رسالة","profile":"البروفايل","photo":"الصور والوسائط","block":"حظر","unblock":"إلغاء الحظر","deleteChat":"مسح الشات","report":"إبلاغ","reportSent":"تم الإبلاغ","copy":"نسخ","delete":"مسح","cancel":"إلغاء","save":"حفظ","chooseLang":"اختار اللغة","map":"الخريطة","phone":"افتح على الموبايل"},
  "en": {"online":"online","today":"Today","yesterday":"Yesterday","message":"Message","profile":"Profile","photo":"Media & Photos","block":"Block","unblock":"Unblock","deleteChat":"Delete Chat","report":"Report","reportSent":"Report sent","copy":"Copy","delete":"Delete","cancel":"Cancel","save":"Save","chooseLang":"Choose Language","map":"Map","phone":"Open on phone"},
};
String tr(String key) => trMap[currentLang]![key] ?? key;
bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
void main() => runApp(KaiApp());
enum Type { text, video, map, browser, image, file, audio }
enum MsgStatus { sent, delivered, read }
class Msg { bool isMe; Type type; String text; String url; MsgStatus status; DateTime time; Msg({required this.isMe, required this.type, required this.text, this.url='', this.status = MsgStatus.sent, DateTime? time}) : time = time?? DateTime.now(); }
String kaiName = "Kai"; String kaiImage = 'assets/kai.png'; Uint8List? pickedImageBytes;
class KaiApp extends StatelessWidget { @override Widget build(BuildContext c) => MaterialApp(debugShowCheckedModeBanner: false, home: ChatScreen()); }
Widget buildTicks(MsgStatus s, bool isDark) {
  if (s == MsgStatus.sent) return Icon(Icons.done, size: 15, color: isDark ? Colors.white70 : Colors.black54);
  if (s == MsgStatus.delivered) return Icon(Icons.done_all, size: 15, color: isDark ? Colors.white70 : Colors.black54);
  return Icon(Icons.done_all, size: 15, color: Color(0xFF53BDEB));
}
class ChatScreen extends StatefulWidget { @override State<ChatScreen> createState() => _S(); }
class _S extends State<ChatScreen> {
  TextEditingController tc = TextEditingController();
  ScrollController scrollCtrl = ScrollController();
  FocusNode focusNode = FocusNode();
  bool showEmoji = false; bool isDark = false; bool showKeyboard = false; int currentLangIndex = 0; bool hasText = false; bool isRecording = false;
  List<String> emojis = ["😊","🙂","👍","❤️","😂","😍","🥺","🔥","👏","🙏"];
  List<Msg> msgs = [ Msg(isMe: false, type: Type.text, text: 'تمام يا بيمبو', time: DateTime.now().subtract(Duration(days: 1))), Msg(isMe: true, type: Type.text, text: 'جرب تدوس عليا دوسة طويلة 😊', time: DateTime.now()), ];
  String getDateLabel(DateTime date){ final now = DateTime.now(); final yesterday = now.subtract(Duration(days: 1)); if (isSameDay(date, now)) return tr("today"); if (isSameDay(date, yesterday)) return tr("yesterday"); return "${date.day}/${date.month}/${date.year}"; }
  Widget dateChip(String label){ return Center(child: Container(margin: EdgeInsets.symmetric(vertical: 12), padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: isDark ? Color(0xFF132845) : Color(0xFFE8DCC0), borderRadius: BorderRadius.circular(12)), child: Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54))));}
  void showLangSheet(){ showModalBottomSheet(context: context, backgroundColor: isDark ? Color(0xFF0A1F3A) : Colors.white, builder: (ctx) => ListView(shrinkWrap: true, children: [ ListTile(title: Text("🇪🇬 العربية"), onTap: () { setState(() => currentLang = "ar"); Navigator.pop(ctx); }), ListTile(title: Text("🇺🇸 English"), onTap: () { setState(() => currentLang = "en"); Navigator.pop(ctx); }), ]));}
  @override void initState(){ super.initState(); tc.addListener(() => setState(() => hasText = tc.text.trim().isNotEmpty)); }
  final ImagePicker picker = ImagePicker(); final AudioRecorder audioRecorder = AudioRecorder();
  void send(Type type, String text, {String url = ''}){ setState(() => msgs.add(Msg(isMe: true, type: type, text: text, url: url, time: DateTime.now()))); tc.clear(); }
  void showMsgOptions(Msg m, int index){ showModalBottomSheet(context: context, backgroundColor: isDark ? Color(0xFF0A1F3A) : Colors.white, builder: (ctx) => Wrap(children: [ ListTile(leading: Icon(Icons.copy), title: Text(tr("copy")), onTap: () => Navigator.pop(ctx)), ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text(tr("delete"), style: TextStyle(color: Colors.red)), onTap: () { setState(() => msgs.removeAt(index)); Navigator.pop(ctx); }), ])); }
  Future<void> pickRealImage() async { final XFile? file = await picker.pickImage(source: ImageSource.gallery); if (file != null) send(Type.image, file.name, url: file.path); }
  Future<void> pickCamera() async { final XFile? file = await picker.pickImage(source: ImageSource.camera); if (file != null) send(Type.image, file.name, url: file.path); }
  Future<void> pickRealFile() async { final result = await FilePicker.platform.pickFiles(type: FileType.any); if (result != null && result.files.isNotEmpty) send(Type.file, result.files.first.name, url: result.files.first.path ?? ''); }
  Future<void> pickRealLocation() async { try { var p = await Geolocator.requestPermission(); Position pos = await Geolocator.getCurrentPosition(); send(Type.map, "${pos.latitude}, ${pos.longitude}", url: "${pos.latitude},${pos.longitude}"); } catch(e){ send(Type.map, "31.265, 32.301"); } }
  Future<void> startStopRecording() async { try { if (isRecording) { String? path = await audioRecorder.stop(); setState(() => isRecording = false); if (path != null) send(Type.audio, "Voice Note", url: path); } else { if (await audioRecorder.hasPermission()) { await audioRecorder.start(const RecordConfig(), path: "voice.m4a"); setState(() => isRecording = true); } } } catch(e){ setState(()=> isRecording = false); } }
  void showAttachSheet(){ showModalBottomSheet(context: context, backgroundColor: isDark ? Color(0xFF0A1F3A) : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) => Padding(padding: EdgeInsets.all(16), child: GridView.count(crossAxisCount: 4, shrinkWrap: true, children: [ _roundBtn(Icons.videocam, 'كاميرا', Color(0xFF007AFF), () { Navigator.pop(ctx); pickCamera(); }), _roundBtn(Icons.map, 'خريطة', Color(0xFF34C759), () { Navigator.pop(ctx); pickRealLocation(); }), _roundBtn(Icons.language, 'جوجل', Color(0xFF5856D6), () { Navigator.pop(ctx); send(Type.browser, 'جوجل', url: 'https://google.com'); }), _roundBtn(Icons.image, 'صورة', Color(0xFFFF2D2E), () { Navigator.pop(ctx); pickRealImage(); }), _roundBtn(Icons.insert_drive_file, 'ملف', Color(0xFFFF7A00), () { Navigator.pop(ctx); pickRealFile(); }), ]))); }
  Widget _roundBtn(IconData icon, String label, Color col, VoidCallback tap){ return InkWell(onTap: tap, child: Column(mainAxisSize: MainAxisSize.min, children: [ CircleAvatar(radius: 28, backgroundColor: col, child: Icon(icon, color: Colors.white, size: 26)), SizedBox(height: 8), Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12)) ])); }
  Widget bubble(Msg m, int index){
    Widget content;
    if (m.type == Type.map){ content = kIsWeb ? Container(height: 200, width: 260, color: Colors.grey[300], child: Center(child: Text(tr("map")))) : SizedBox(height: 200, width: 260, child: FlutterMap(options: MapOptions(initialCenter: LatLng(31.265, 32.301), initialZoom: 14), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png')])); }
    else if (m.type == Type.browser){ content = kIsWeb ? Container(height: 250, width: 260, color: Colors.black12, child: Center(child: Text(tr("phone")))) : SizedBox(height: 250, width: 260, child: WebViewWidget(controller: WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted)..loadRequest(Uri.parse(m.url)))); }
    else if (m.type == Type.image){ if (m.url.isNotEmpty && !kIsWeb && File(m.url).existsSync()){ content = ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(m.url), height: 160, width: 240, fit: BoxFit.cover)); } else { content = Container(height: 160, width: 240, color: Colors.grey, child: Icon(Icons.image, size: 50, color: Colors.white)); } }
    else if (m.type == Type.file){ content = Container(width: 240, padding: EdgeInsets.all(10), child: Row(children: [Icon(Icons.insert_drive_file), SizedBox(width: 6), Expanded(child: Text(m.text))])); }
    else if (m.type == Type.audio){ content = Container(width: 240, padding: EdgeInsets.all(12), child: Text('🎤 Voice Note')); }
    else { content = Padding(padding: EdgeInsets.all(14), child: Text(m.text, style: TextStyle(color: m.isMe ? (isDark ? Color(0xFF0A1F3A) : Colors.white) : (isDark ? Colors.white : Color(0xFF0A1F3A)), fontSize: 14))); }
    Color col = isDark ? (m.isMe ? Color(0xFFF5E6C8) : Color(0xFF132845)) : (m.isMe ? Color(0xFF0A1F3A) : Color(0xFFFFFFFF));
    Widget avatarKai = CircleAvatar(radius: 18, backgroundImage: pickedImageBytes != null ? MemoryImage(pickedImageBytes!) : AssetImage(kaiImage) as ImageProvider);
    Widget avatarMe = CircleAvatar(radius: 18, backgroundImage: AssetImage('assets/bimbo.png'));
    Widget msgBox = Container(constraints: BoxConstraints(maxWidth: 260), decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(16)), child: Stack(children: [ Padding(padding: EdgeInsets.fromLTRB(8, 8, 8, 22), child: content), Positioned(bottom: 4, right: 8, child: Row(children: [ Text("${m.time.hour}:${m.time.minute.toString().padLeft(2, '0')}", style: TextStyle(fontSize: 10, color: Colors.grey)), if (m.isMe) buildTicks(m.status, isDark) ])) ]));
    return Padding(padding: EdgeInsets.symmetric(vertical: 4, horizontal: 10), child: GestureDetector(onLongPress: () => showMsgOptions(m, index), child: Row(mainAxisAlignment: m.isMe ? MainAxisAlignment.end : MainAxisAlignment.start, children: [ if (!m.isMe) avatarKai, Flexible(child: msgBox), if (m.isMe) avatarMe ])));
  }
  @override Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0A1F3A) : Color(0xFFF5E6C8),
      appBar: AppBar(backgroundColor: Color(0xFF0A1F3A), title: Row(children: [ GestureDetector(onTap: () async { final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => KaiProfilePage(allMsgs: msgs, isDarkMode: isDark))); if (result == true) setState(() => msgs.clear()); }, child: CircleAvatar(radius: 20, backgroundImage: pickedImageBytes != null ? MemoryImage(pickedImageBytes!) : AssetImage(kaiImage) as ImageProvider)), SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(kaiName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)), Text(tr("online"), style: TextStyle(fontSize: 12, color: Colors.white70)) ]) ]), actions: [ IconButton(icon: Icon(Icons.language, color: Colors.white), onPressed: showLangSheet) ]),
      body: Column(children: [
        Expanded(child: ListView.builder(controller: scrollCtrl, itemCount: msgs.length, itemBuilder: (_, i){ bool showDate = i==0 ? true : !isSameDay(msgs[i].time, msgs[i-1].time); return Column(children: [ if (showDate) dateChip(getDateLabel(msgs[i].time)), bubble(msgs[i], i) ]); })),
        Container(color: isDark ? Color(0xFF0A1F3A) : Colors.white, padding: EdgeInsets.all(6), child: Row(children:[ Expanded(child: Container(padding: EdgeInsets.symmetric(horizontal:8), decoration: BoxDecoration(color: isDark ? Color(0xFF132845) : Color(0xFFFFF8EC), borderRadius:BorderRadius.circular(24)), child: Row(children: [ GestureDetector(onTap:showAttachSheet, child: Icon(Icons.attach_file, color: Colors.grey)), SizedBox(width:8), Expanded(child:TextField(controller:tc, focusNode: focusNode, decoration:InputDecoration(hintText: tr("message"), border:InputBorder.none))), ]))), SizedBox(width:6), GestureDetector(onTap: (){ if(hasText){ send(Type.text,tc.text); } else { startStopRecording(); } }, child: CircleAvatar(backgroundColor: isDark ? Color(0xFFF5E6C8) : Color(0xFF0A1F3A), child: Icon(isRecording ? Icons.stop : (hasText? Icons.send : Icons.mic), color: isDark ? Color(0xFF0A1F3A) : Colors.white))) ]))
      ])
    );
  }
}
class MediaGalleryPage extends StatelessWidget {
  final List<Msg> allMsgs; MediaGalleryPage({required this.allMsgs});
  @override Widget build(BuildContext context){
    List<Msg> mediaMsgs = allMsgs.where((m) => m.type == Type.image || m.type == Type.video || m.type == Type.file).toList();
    return Scaffold(backgroundColor: Color(0xFF0A1F3A), appBar: AppBar(backgroundColor: Color(0xFF0A1F3A), title: Text(tr("photo"), style: TextStyle(color: Colors.white))), body: mediaMsgs.isEmpty ? Center(child: Text(tr("photo"), style: TextStyle(color: Colors.white70))) : GridView.builder(padding: EdgeInsets.all(8), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3), itemCount: mediaMsgs.length, itemBuilder: (_, i) => Container(color: Colors.grey, child: Icon(Icons.image))));
  }
}
class KaiProfilePage extends StatefulWidget {
  final List<Msg> allMsgs; final bool isDarkMode; KaiProfilePage({required this.allMsgs, this.isDarkMode = false});
  @override State<KaiProfilePage> createState() => _KaiProfilePageState();
}
class _KaiProfilePageState extends State<KaiProfilePage> {
  bool isBlocked = false;
  Future<void> pickImage() async { final picker = ImagePicker(); final XFile? image = await picker.pickImage(source: ImageSource.gallery); if (image != null){ final bytes = await image.readAsBytes(); setState(() { pickedImageBytes = bytes; }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved"))); } }
  @override Widget build(BuildContext context){
    bool isDark = widget.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0A1F3A) : Color(0xFFF5E6C8),
      appBar: AppBar(backgroundColor: Color(0xFF0A1F3A), title: Text(tr("profile"), style: TextStyle(color: Colors.white))),
      body: ListView(children: [
        SizedBox(height: 20),
        Center(child: GestureDetector(onTap: pickImage, child: CircleAvatar(radius: 60, backgroundImage: pickedImageBytes != null ? MemoryImage(pickedImageBytes!) : AssetImage(kaiImage) as ImageProvider))),
        SizedBox(height: 12),
        Center(child: Text(kaiName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black))),
        Center(child: Text(tr("online"), style: TextStyle(color: Colors.green))),
        Divider(height: 30),
        ListTile(leading: Icon(Icons.photo), title: Text(tr("photo")), onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => MediaGalleryPage(allMsgs: widget.allMsgs))); }),
        ListTile(leading: Icon(isBlocked ? Icons.lock_open : Icons.block, color: isBlocked ? Colors.green : Colors.red), title: Text(isBlocked ? tr("unblock") : tr("block")), onTap: () { setState(() { isBlocked = !isBlocked; }); }),
        ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text(tr("deleteChat")), onTap: () { showDialog(context: context, builder: (d) => AlertDialog(title: Text(tr("deleteChat")), actions: [ TextButton(onPressed: () => Navigator.pop(d), child: Text(tr("cancel"))), TextButton(onPressed: () { Navigator.pop(d); Navigator.pop(context, true); }, child: Text(tr("delete"), style: TextStyle(color: Colors.red))) ])); }),
        ListTile(leading: Icon(Icons.report, color: Colors.orange), title: Text(tr("report")), onTap: () { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr("reportSent")))); })
      ])
    );
  }
}