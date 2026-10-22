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
import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';

String currentLang = "ar";
Map<String, Map<String, String>> trMap = {
  "ar": {"online":"متصل الآن","today":"اليوم","yesterday":"أمس","message":"رسالة","recording":"تسجيل...","chooseLang":"اختار اللغة","edit":"تعديل","editMessage":"تعديل الرسالة","cancel":"إلغاء","save":"حفظ","delete":"مسح","deleted":"تم المسح","forward":"إعادة توجيه","forwarded":"تمت إعادة التوجيه","saveGallery":"تم الحفظ","copy":"نسخ","copied":"تم النسخ","profile":"البروفايل","photo":"الصور والوسائط","block":"حظر","unblock":"إلغاء الحظر","deleteChat":"مسح الشات","report":"إبلاغ","reportSent":"تم الإبلاغ","comingSoon":"قريباً","editProfile":"تعديل البروفايل","tapToChange":"دوس على الصورة عشان تغيرها","name":"الاسم","tapToEdit":"دوس على الصورة عشان تعدل","map":"الخريطة","phone":"افتح على الموبايل"},
  "en": {"online":"online","today":"Today","yesterday":"Yesterday","message":"Message","recording":"Recording...","chooseLang":"Choose Language","edit":"Edit","editMessage":"Edit Message","cancel":"Cancel","save":"Save","delete":"Delete","deleted":"Deleted","forward":"Forward","forwarded":"Forwarded","saveGallery":"Saved to gallery","copy":"Copy","copied":"Copied","profile":"Profile","photo":"Media & Photos","block":"Block","unblock":"Unblock","deleteChat":"Delete Chat","report":"Report","reportSent":"Report sent","comingSoon":"Coming soon","editProfile":"Edit Profile","tapToChange":"Tap image to change","name":"Name","tapToEdit":"Tap image to edit","map":"Map","phone":"Open on phone"},
};

String tr(String key) => trMap[currentLang]![key] ?? key;
bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

void main() => runApp(KaiApp());

enum Type { text, video, map, browser, image, file, audio }
enum MsgStatus { sent, delivered, read }

class Msg {
  bool isMe;
  Type type;
  String text;
  String url;
  MsgStatus status;
  DateTime time;
  Msg({required this.isMe, required this.type, required this.text, this.url='', this.status = MsgStatus.sent, DateTime? time}) : time = time?? DateTime.now();
}

String kaiName = "Kai";
String kaiImage = 'assets/kai.png';
Uint8List? pickedImageBytes;

class KaiApp extends StatelessWidget {
  @override
  Widget build(BuildContext c) => MaterialApp(debugShowCheckedModeBanner: false, home: ChatScreen());
}

Widget buildTicks(MsgStatus s, bool isDark) {
  if (s == MsgStatus.sent) return Icon(Icons.done, size: 15, color: isDark ? Colors.white70 : Colors.black54);
  if (s == MsgStatus.delivered) return Icon(Icons.done_all, size: 15, color: isDark ? Colors.white70 : Colors.black54);
  return Icon(Icons.done_all, size: 15, color: Color(0xFF53BDEB));
}

class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => _S();
}

class _S extends State<ChatScreen> {
  TextEditingController tc = TextEditingController();
  ScrollController scrollCtrl = ScrollController();
  FocusNode focusNode = FocusNode();
  bool showEmoji = false;
  bool isDark = false;
  bool showKeyboard = false;
  int currentLangIndex = 0;

  List<String> emojis = ["😊","🙂","👍","❤️","😂","😍","🥺","🔥","👏","🙏","😅","😎","🤔","😭","😘","👌","💪","🎉","✨","😁"];
  List<Msg> msgs = [
    Msg(isMe: false, type: Type.text, text: 'تمام يا بيمبو - دوسة طويلة هتطلع القايمة!', time: DateTime.now().subtract(Duration(days: 1))),
    Msg(isMe: true, type: Type.text, text: 'جرب تدوس عليا دوسة طويلة 😊', time: DateTime.now()),
    Msg(isMe: false, type: Type.image, text: 'photo', time: DateTime.now()),
  ];

  List<Msg> get mediaMsgs {
    List<Msg> allMsgs = msgs;
    return allMsgs.where((Msg m) => m.type == Type.image || m.type == Type.video || m.type == Type.file).toList();
  }

  String getDateLabel(DateTime date){
    final now = DateTime.now();
    final yesterday = now.subtract(Duration(days: 1));
    if (isSameDay(date, now)) return tr("today");
    if (isSameDay(date, yesterday)) return tr("yesterday");
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget dateChip2(String label){
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 12),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF132845) : Color(0xFFE8DCC0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
      ),
    );
  }

  void showLangSheet(){
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Color(0xFF0A1F3A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          children: [
            Padding(padding: EdgeInsets.all(16), child: Text(tr("chooseLang"), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black))),
            ListTile(title: Text("🇪🇬 العربية"), onTap: () { setState(() => currentLang = "ar"); Navigator.pop(ctx); }),
            ListTile(title: Text("🇺🇸 English"), onTap: () { setState(() => currentLang = "en"); Navigator.pop(ctx); }),
          ],
        );
      },
    );
  }
  
 void showAttachSheet() {
  showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? Color(0xFF0A1F3A) : Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        children: [
          _roundBtn(ctx, Icons.videocam, 'كاميرا', Color(0xFF007AFF), () { Navigator.pop(ctx); pickCamera(); }),
          _roundBtn(ctx, Icons.map, 'خريطة', Color(0xFF34C759), () { Navigator.pop(ctx); pickRealLocation(); }),
          _roundBtn(ctx, Icons.language, 'جوجل', Color(0xFF5856D6), () { Navigator.pop(ctx); send(Type.browser, 'جوجل', url: 'https://google.com'); }),
          _roundBtn(ctx, Icons.image, 'صورة', Color(0xFFFF2D2E), () { Navigator.pop(ctx); pickRealImage(); }),
          _roundBtn(ctx, Icons.insert_drive_file, 'ملف', Color(0xFFFF7A00), () { Navigator.pop(ctx); pickRealFile(); }),
        ],
      ),
    ),
  );
}

Widget _roundBtn(BuildContext ctx, IconData icon, String label, Color col, VoidCallback tap) {
  return InkWell(
    onTap: tap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 28, backgroundColor: col, child: Icon(icon, color: Colors.white, size: 26)),
        SizedBox(height: 8),
        Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12))
      ],
    ),
  );
}

Widget buildEmojiPicker() {
  return Container(
    height: 250,
    color: isDark ? Color(0xFF0A1F3A) : Color(0xFFF5E6C8),
    child: GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
      itemCount: emojis.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () { setState(() => tc.text += emojis[i]); },
        child: Center(child: Text(emojis[i], style: TextStyle(fontSize: 26))),
      ),
    ),
  );
}

Widget bubble(Msg m, int index) {
  Widget content;
  if (m.type == Type.map) {
    if (kIsWeb) {
      content = Container(height: 200, width: 260, color: Colors.grey[300], child: Center(child: Text(tr("map"))));
    } else {
      content = SizedBox(
        height: 200, width: 260,
        child: FlutterMap(
          options: MapOptions(initialCenter: LatLng(31.265, 32.301), initialZoom: 14),
          children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png')],
        ),
      );
    }
  } else if (m.type == Type.browser || m.type == Type.video) {
    if (kIsWeb) {
      content = Container(height: 250, width: 260, color: Colors.black12, child: Center(child: Text(tr("phone"))));
    } else {
      content = SizedBox(height: 250, width: 260, child: WebViewWidget(controller: WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted)..loadRequest(Uri.parse(m.url))));
    }
  } else if (m.type == Type.audio) {
    content = Container(width: 240, padding: EdgeInsets.all(12), child: Text('🎤 0:12 Recording', style: TextStyle(color: isDark ? Colors.white : Color(0xFF1E1E1E))));
  } else if (m.type == Type.image) {
    if (m.url.isNotEmpty && !kIsWeb && File(m.url).existsSync()) {
      content = ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(m.url), height: 160, width: 240, fit: BoxFit.cover));
    } else {
      content = Container(height: 160, width: 240, color: Colors.grey, child: Icon(Icons.image, size: 50, color: Colors.white));
    }
  } else if (m.type == Type.file) {
    content = Container(width: 240, padding: EdgeInsets.all(10), child: Row(children: [Icon(Icons.insert_drive_file, color: isDark ? Colors.white : Color(0xFF1E1E1E)), SizedBox(width: 6), Expanded(child: Text(m.text, style: TextStyle(color: isDark ? Colors.white : Color(0xFF1E1E1E))))]));
  } else {
    content = Padding(padding: EdgeInsets.all(14), child: Text(m.text, style: TextStyle(color: m.isMe ? (isDark ? Color(0xFF0A1F3A) : Colors.white) : (isDark ? Colors.white : Color(0xFF0A1F3A)), fontSize: 14)));
  }

  Color col;
  if (isDark) {
    col = m.isMe ? Color(0xFFF5E6C8) : Color(0xFF132845);
  } else {
    col = m.isMe ? Color(0xFF0A1F3A) : Color(0xFFFFFFFF);
  }

  Widget avatarKai = Stack(children: [
    CircleAvatar(radius: 18, backgroundImage: pickedImageBytes != null ? MemoryImage(pickedImageBytes!) : AssetImage(kaiImage) as ImageProvider),
    Positioned(bottom: 0, right: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(0xFF8BC34A), shape: BoxShape.circle, border: Border.all(color: isDark ? Color(0xFF0A1F3A) : Colors.white, width: 1.5))))
  ]);

  Widget avatarMe = Stack(children: [
    CircleAvatar(radius: 18, backgroundImage: AssetImage('assets/bimbo.png')),
    Positioned(bottom: 0, right: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(0xFF8BC34A), shape: BoxShape.circle, border: Border.all(color: isDark ? Color(0xFF0A1F3A) : Colors.white, width: 1.5))))
  ]);

  Widget msgBox = Container(
    constraints: BoxConstraints(maxWidth: 260),
    decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(16), boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)]),
    child: Stack(children: [
      Padding(padding: EdgeInsets.fromLTRB(8, 8, 8, 22), child: content),
      Positioned(bottom: 4, right: 8, child: Row(children: [ Text("${m.time.hour}:${m.time.minute.toString().padLeft(2,'0')}", style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black54)), SizedBox(width: 4), if(m.isMe) buildTicks(m.status, isDark), ]))
    ]),
  );

  return Padding(
    padding: EdgeInsets.symmetric(vertical:4,horizontal:10),
    child: GestureDetector(
      onLongPress: ()=> showMsgOptions(m, index),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: m.isMe? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if(!m.isMe) avatarKai,
          if(!m.isMe) SizedBox(width: 6),
          Flexible(child: msgBox),
          if(m.isMe) SizedBox(width: 6),
          if(m.isMe) avatarMe,
        ],
      ),
    ),
  );
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: isDark ? Color(0xFF0A1F3A) : Color(0xFFF5E6C8),
    appBar: AppBar(
      backgroundColor: Color(0xFF0A1F3A),
      elevation: isDark ? 0 : 0.5,
      title: Row(children: [
        GestureDetector(
          onTap: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => KaiProfilePage(allMsgs: msgs, isDarkMode: isDark)));
            if (result == true) { setState(() { msgs.clear(); }); }
          },
          child: Stack(children: [
            CircleAvatar(radius: 20, backgroundImage: pickedImageBytes != null ? MemoryImage(pickedImageBytes!) : AssetImage(kaiImage) as ImageProvider),
            Positioned(bottom: 0, right: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Color(0xFF8BC34A), shape: BoxShape.circle, border: Border.all(color: Color(0xFF0A1F3A), width: 2))))
          ]),
        ),
        SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(kaiName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)), Text(tr("online"), style: TextStyle(fontSize: 12, color: Colors.white70)), ]),
      ]),
      actions: [
        Padding(padding: EdgeInsets.only(right: 12), child: GestureDetector(onTap: () => setState(() => isDark = !isDark), child: Container(width: 28, height: 28, decoration: BoxDecoration(color: isDark ? Color(0xFFF5E6C8) : Colors.white, shape: BoxShape.circle)))),
        IconButton(icon: Icon(Icons.language, color: Colors.white), onPressed: showLangSheet),
      ],
    ),
    body: Column(children: [
      Expanded(child: ListView.builder(controller: scrollCtrl, itemCount: msgs.length, itemBuilder: (_, i) { bool showDate = true; if (i > 0) { showDate = !isSameDay(msgs[i].time, msgs[i-1].time); } return Column(children: [ if (showDate) dateChip2(getDateLabel(msgs[i].time)), bubble(msgs[i], i), ]); }, ), ),
      if (_isKaiTyping) Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 6), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: isDark ? Color(0xFFF5E6C8) : Colors.white, borderRadius: BorderRadius.circular(16)), child: Row(mainAxisSize: MainAxisSize.min, children: [ CircleAvatar(radius: 10, backgroundImage: pickedImageBytes != null ? MemoryImage(pickedImageBytes!) : AssetImage(kaiImage) as ImageProvider), SizedBox(width: 8), Text("Kai is typing...", style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black54)), ])))),
      Container(color: isDark ? Color(0xFF0A1F3A) : Colors.white, padding: EdgeInsets.all(6), child: Row(children:[ Expanded(child: Container(padding: EdgeInsets.symmetric(horizontal:8), decoration: BoxDecoration(color: isDark ? Color(0xFF132845) : Color(0xFFFFF8EC), borderRadius:BorderRadius.circular(24), border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade300)), child: Row(children: [ GestureDetector(onTap:(){ setState(()=> showEmoji = !showEmoji); if(showEmoji) focusNode.unfocus(); else focusNode.requestFocus(); }, child: Icon(showEmoji? Icons.keyboard : Icons.emoji_emotions_outlined, color: isDark ? Colors.white70 : Colors.grey[600])), SizedBox(width:6), GestureDetector(onTap:showAttachSheet, child: Icon(Icons.attach_file, color: isDark ? Colors.white70 : Colors.grey[600])), SizedBox(width:8), Expanded(child:TextField(controller:tc, focusNode: focusNode, style: TextStyle(color: isDark ? Colors.white : Colors.black), onTap: (){ setState(()=> showKeyboard=false); }, decoration:InputDecoration(hintText: tr("message"), hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey), border:InputBorder.none))), GestureDetector(onTap: ()=> setState(()=> showKeyboard = !showKeyboard), child: Icon(showKeyboard? Icons.keyboard_hide : Icons.language, color: isDark ? Colors.white70 : Colors.grey[600])), ]))), SizedBox(width:6), GestureDetector(onLongPress: startStopRecording, onTap: (){ if(hasText){ send(Type.text,tc.text); tc.clear(); } else { startStopRecording(); } }, child: CircleAvatar(backgroundColor: isDark ? Color(0xFFF5E6C8) : Color(0xFF0A1F3A), child: Icon(isRecording ? Icons.stop : (hasText? Icons.send : Icons.mic), color: isDark ? Color(0xFF0A1F3A) : Colors.white))), ])),
      if(showEmoji) buildEmojiPicker(),
      if(showKeyboard) MultiLanguageKeyboard(controller: tc, currentLang: currentLangIndex, onChangeLang: (i)=> setState(()=> currentLangIndex=i), onHide: ()=> setState(()=> showKeyboard=false), onSend: (){ send(Type.text,tc.text); tc.clear(); }, isDark: isDark),
    ]),
  );
}

  // ===== باقي الكلاسات - سيبهم زي ما هما - بره كلاس _S =====
class MediaGalleryPage extends StatelessWidget {
  final List<Msg> allMsgs;
  MediaGalleryPage({required this.allMsgs});
  @override
  Widget build(BuildContext context) {
    List<Msg> mediaMsgs = allMsgs
        .where((Msg m) => m.type == Type.image || m.type == Type.video || m.type == Type.file)
        .toList();
    return Scaffold(
      backgroundColor: Color(0xFF0A1F3A),
      appBar: AppBar(
        backgroundColor: Color(0xFF0A1F3A),
        title: Text(tr("photo"), style: TextStyle(color: Colors.white)),
      ),
      body: mediaMsgs.isEmpty
          ? Center(child: Text(tr("comingSoon"), style: TextStyle(color: Colors.white70)))
          : GridView.builder(
              padding: EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
              itemCount: mediaMsgs.length,
              itemBuilder: (_, i) {
                var m = mediaMsgs[i];
                if (m.type == Type.image) return Container(color: Colors.grey[300], child: Icon(Icons.image, size: 40, color: Colors.white));
                if (m.type == Type.video) return Container(color: Colors.black87, child: Icon(Icons.videocam, size: 40, color: Colors.white));
                return Container(color: Color(0xFFF5E6C8), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.insert_drive_file, color: Colors.orange), Text(m.text, style: TextStyle(fontSize: 10))]));
              },
            ),
    );
  }
}

class MultiLanguageKeyboard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onHide;
  final VoidCallback onSend;
  final int currentLang;
  final Function(int) onChangeLang;
  final bool isDark;
  MultiLanguageKeyboard(
      {required this.controller,
      required this.onHide,
      required this.onSend,
      required this.currentLang,
      required this.onChangeLang,
      required this.isDark});

  final List<Map<String, dynamic>> languages = [
    {
      "name": "English",
      "keys": [
        'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', 'a', 's', 'd', 'f',
        'g', 'h', 'j', 'k', 'l', 'z', 'x', 'c', 'v', 'b', 'n', 'm'
      ]
    },
    {
      "name": "العربية",
      "keys": [
        'ض', 'ص', 'ث', 'ق', 'ف', 'غ', 'ع', 'ه', 'خ', 'ح', 'ش', 'س', 'ي',
        'ب', 'ل', 'ا', 'ت', 'ن', 'م', 'ك', 'ط', 'ئ', 'ء', 'ؤ', 'ر', 'ى',
        'ة', 'و', 'ظ', 'د', 'ذ'
      ]
    },
    {
      "name": "Français",
      "keys": [
        'a', 'z', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', 'q', 's', 'd',
        'f', 'g', 'h', 'j', 'k', 'l', 'm', 'w', 'x', 'c', 'v', 'b', 'n',
        'é', 'è', 'à', 'ç'
      ]
    },
    {
      "name": "Deutsch",
      "keys": [
        'q', 'w', 'e', 'r', 't', 'z', 'u', 'i', 'o', 'p', 'ü', 'a', 's',
        'd', 'f', 'g', 'h', 'j', 'k', 'l', 'ö', 'ä', 'y', 'x', 'c', 'v',
        'b', 'n', 'm', 'ß'
      ]
    },
    {
      "name": "Español",
      "keys": [
        'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', 'a', 's', 'd',
        'f', 'g', 'h', 'j', 'k', 'l', 'ñ', 'z', 'x', 'c', 'v', 'b', 'n',
        'm', 'á', 'é', 'í'
      ]
    },
    {
      "name": "Italiano",
      "keys": [
        'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', 'a', 's', 'd',
        'f', 'g', 'h', 'j', 'k', 'l', 'ò', 'à', 'z', 'x', 'c', 'v', 'b',
        'n', 'm', 'è', 'é', 'ì'
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<String> currentKeys = languages[currentLang]["keys"];
    return Container(
      color: isDark ? Color(0xFF0A1F3A) : Color(0xFFF5E6C8),
      padding: EdgeInsets.all(6),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
              icon: Icon(Icons.keyboard_hide,
                  color: isDark ? Colors.white : Colors.black),
              onPressed: onHide),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(languages.length, (index) {
                  bool isSelected = index == currentLang;
                  return GestureDetector(
                    onTap: () => onChangeLang(index),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 3),
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? Color(0xFFF5E6C8) : Color(0xFF0A1F3A))
                            : (isDark ? Color(0xFF132845) : Colors.white),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        languages[index]["name"],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? (isDark ? Color(0xFF0A1F3A) : Colors.white)
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          IconButton(
              icon: Icon(Icons.send,
                  color: isDark ? Color(0xFFF5E6C8) : Color(0xFF0A1F3A)),
              onPressed: onSend),
        ]),
        SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            ...currentKeys.map(
              (k) => InkWell(
                onTap: () => controller.text += k,
                child: Container(
                  width: 32,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF132845) : Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(k,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black)),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                if (controller.text.isNotEmpty) {
                  controller.text = controller.text
                      .substring(0, controller.text.length - 1);
                }
              },
              child: Container(
                width: 60,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Color(0xFF9CA3AF),
                    borderRadius: BorderRadius.circular(5)),
                child: Icon(Icons.backspace, size: 18),
              ),
            ),
            InkWell(
              onTap: () => controller.text += " ",
              child: Container(
                width: 150,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF132845) : Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text("SPACE",
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black)),
              ),
            ),
          ],
        ),
      ]),
    );
  }
}

class KaiProfilePage extends StatefulWidget {
  final List<Msg> allMsgs;
  final bool isDarkMode;
  KaiProfilePage({required this.allMsgs, this.isDarkMode = false});
  @override
  State<KaiProfilePage> createState() => _KaiProfilePageState();
}

class _KaiProfilePageState extends State<KaiProfilePage> {
  bool isBlocked = false;
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        pickedImageBytes = bytes;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr("saveGallery"))));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = widget.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0A1F3A) : Color(0xFFF5E6C8),
      appBar: AppBar(
        backgroundColor: Color(0xFF0A1F3A),
        elevation: 0,
        title: Text(tr("profile"), style: TextStyle(color: Colors.white)),
      ),
      body: ListView(children: [
        SizedBox(height: 20),
        Center(
          child: Stack(children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: pickedImageBytes != null
                    ? MemoryImage(pickedImageBytes!)
                    : AssetImage(kaiImage) as ImageProvider,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Color(0xFF8BC34A),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isDark ? Color(0xFF0A1F3A) : Colors.white,
                      width: 3),
                ),
              ),
            )
          ]),
        ),
        SizedBox(height: 8),
        Center(
          child: Text(tr("tapToChange"),
              style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 12)),
        ),
        SizedBox(height: 12),
        Center(
          child: Text(kaiName,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black)),
        ),
        SizedBox(height: 4),
        Center(child: Text(tr("online"), style: TextStyle(color: Colors.green))),
        Divider(height: 30, color: isDark ? Colors.white24 : Colors.black12),
        ListTile(
          leading: Icon(Icons.person,
              color: isDark ? Color(0xFFF5E6C8) : Color(0xFF0A1F3A)),
          title: Text(tr("editProfile"),
              style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          subtitle: Text("${tr("name")}: $kaiName",
              style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54)),
          onTap: () {
            final ctrl = TextEditingController(text: kaiName);
            showDialog(
              context: context,
              builder: (d) => AlertDialog(
                backgroundColor: isDark ? Color(0xFF0A1F3A) : Colors.white,
                title: Text(tr("editProfile"),
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black)),
                content: TextField(
                  controller: ctrl,
                  style:
                      TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(labelText: tr("name")),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(d),
                      child: Text(tr("cancel"))),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        kaiName = ctrl.text;
                      });
                      Navigator.pop(d);
                    },
                    child: Text(tr("save")),
                  ),
                ],
              ),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.photo,
              color: isDark ? Color(0xFFF5E6C8) : Color(0xFF0A1F3A)),
          title: Text(tr("photo"),
              style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => MediaGalleryPage(allMsgs: widget.allMsgs)));
          },
        ),
        ListTile(
          leading: Icon(isBlocked ? Icons.lock_open : Icons.block,
              color: isBlocked ? Colors.green : Colors.red),
          title: Text(isBlocked ? tr("unblock") : tr("block"),
              style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          onTap: () {
            setState(() => isBlocked = !isBlocked);
          },
        ),
        ListTile(
          leading: Icon(Icons.delete, color: Colors.red),
          title: Text(tr("deleteChat"),
              style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          onTap: () {
            showDialog(
              context: context,
              builder: (d) => AlertDialog(
                backgroundColor: isDark ? Color(0xFF0A1F3A) : Colors.white,
                title: Text(tr("deleteChat"),
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(d),
                      child: Text(tr("cancel"))),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(d);
                      Navigator.pop(context, true);
                    },
                    child:
                        Text(tr("delete"), style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.report, color: Colors.orange),
          title: Text(tr("report"),
              style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          onTap: () {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(tr("reportSent"))));
          },
        ),
      ]),
    );
  }
}