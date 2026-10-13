import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';

class DisplayScreen extends StatefulWidget {
  const DisplayScreen({super.key});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  final _firestore = FirebaseFirestore.instance;

  // ---------- Delete ----------
  Future<void> deleteStudent(String documentId) async {
    await _firestore.collection('student').doc(documentId).delete();
  }

  Future<void> showDeleteConfirmation(String documentId) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบข้อมูล'),
          content: const Text('คุณต้องการลบข้อมูลจริงๆ ใช่ไหมครับ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () async {
                await deleteStudent(documentId);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );
  }

  // ---------- ข้อ 30: Update ----------
  Future<void> updateStudent(String documentId, Map<String, dynamic> data) async {
    await _firestore.collection('student').doc(documentId).update(data);
  }

  Future<void> showEditDialog(QueryDocumentSnapshot document) async {
    final editKey = GlobalKey<FormState>();
    final fname = TextEditingController(text: document["fname"]);
    final lname = TextEditingController(text: document["lname"]);
    final email = TextEditingController(text: document["email"]);
    final score = TextEditingController(text: document["score"]);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('แก้ไขข้อมูล'),
          content: SingleChildScrollView(
            child: Form(
              key: editKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: fname,
                    decoration: const InputDecoration(labelText: 'ชื่อ'),
                    validator: RequiredValidator(errorText: "กรุณาป้อนชื่อด้วยครับ").call,
                  ),
                  TextFormField(
                    controller: lname,
                    decoration: const InputDecoration(labelText: 'นามสกุล'),
                    validator: RequiredValidator(errorText: "กรุณาป้อนนามสกุลด้วยครับ").call,
                  ),
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'อีเมล์'),
                    validator: MultiValidator([
                      EmailValidator(errorText: "รูปแบบอีเมล์ไม่ถูกต้อง"),
                      RequiredValidator(errorText: "กรุณาป้อนอีเมล์ด้วยครับ"),
                    ]).call,
                  ),
                  TextFormField(
                    controller: score,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'คะแนน'),
                    validator: MultiValidator([
                      RequiredValidator(errorText: "กรุณาป้อนคะแนนสอบด้วยครับ"),
                      PatternValidator(r'^[0-9]+$', errorText: "คะแนนต้องเป็นตัวเลขเท่านั้น"),
                    ]).call,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () async {
                if (editKey.currentState!.validate()) {
                  await updateStudent(document.id, {
                    "fname": fname.text,
                    "lname": lname.text,
                    "email": email.text,
                    "score": score.text,
                  });
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("รายงานคะแนนสอบ"),
        backgroundColor: const Color.fromARGB(255, 49, 224, 157),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection("student").snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final document = snapshot.data!.docs[index];
              return Container(
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 30,
                    child: FittedBox(child: Text(document["score"])),
                  ),
                  title: Text(document["fname"] + " " + document["lname"]),
                  subtitle: Text(document["email"]),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          await showEditDialog(document);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await showDeleteConfirmation(document.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
