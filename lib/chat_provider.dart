import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getChats(String userId) {
    return _firestore
        .collection("chats")
        .where('users', arrayContains: userId)
        .snapshots();
  }

  Stream<QuerySnapshot> searchUsers(String query) {
    return _firestore
        .collection("users")
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThanOrEqualTo: query + r'\uf8ff')
        .snapshots();
  }

  Future<void> sendMessage(
      String chatId, String message, String receiverId) async {
    final currentUser = _auth.currentUser;

    if (currentUser != null) {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('message')
          .add({
        'senderId': currentUser.uid,
        'receiverId': receiverId,
        'mesageBody': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('chats').doc(chatId).set({
        'users': [currentUser.uid, receiverId],
        'lastMessage': message,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<String?> getChatRoom(String receiverId) async {
    final currentUser = _auth.currentUser;

    if (currentUser != null) {
      final chatQuery = await _firestore
          .collection('chats')
          .where('users', arrayContains: currentUser.uid)
          .get();

      final chats = chatQuery.docs
          .where((chat) => chat['users'].contains(receiverId))
          .toList();

      if (chats.isNotEmpty) {
        return chats.first.id;
      }
    }
    return null;
  }

  Future<String> createChatRoom(String receiverId) async {
    final currentUser = _auth.currentUser;

    if (currentUser != null) {
      final chatRoom = await _firestore.collection('chats').add({
        'users': [currentUser.uid, receiverId],
        'lastMessage': '',
        'timestamp': FieldValue.serverTimestamp(),
      });
      return chatRoom.id;
    }
    throw Exception('Current User is null');
  }

// Stream<QuerySnapshot> getChats(String userId) {
//   return _firestore
//       .collection("chats")
//       .where('users', arrayContains: userId)
//       .orderBy('timestamp', descending: true) // Son mesaja göre sırala
//       .snapshots();
// }

// Stream<QuerySnapshot> searchUsers(String query) {
//   query = query.toLowerCase().trim(); // Aramayı küçük harfe çevir ve boşlukları kaldır
//   return _firestore
//       .collection("users")
//       .where('email', isGreaterThanOrEqualTo: query)
//       .where('email', isLessThan: query + 'z') // '\uf8ff' yerine 'z' kullan
//       .limit(20) // Sonuç sayısını sınırla
//       .snapshots();
// }

// Future<void> sendMessage(String chatId, String message, String receiverId) async {
//   final currentUser = _auth.currentUser;

//   if (currentUser == null) {
//     throw Exception('Current user is null');
//   }

//   final messageData = {
//     'senderId': currentUser.uid,
//     'receiverId': receiverId,
//     'messageBody': message, // 'mesageBody' yerine 'messageBody' olarak düzeltildi
//     'timestamp': FieldValue.serverTimestamp(),
//   };

//   final chatData = {
//     'users': [currentUser.uid, receiverId],
//     'lastMessage': message,
//     'timestamp': FieldValue.serverTimestamp(),
//   };

//   try {
//     await Future.wait([
//       _firestore
//           .collection('chats')
//           .doc(chatId)
//           .collection('messages') // 'message' yerine 'messages' olarak düzeltildi
//           .add(messageData),
//       _firestore
//           .collection('chats')
//           .doc(chatId)
//           .set(chatData, SetOptions(merge: true))
//     ]);
//   } catch (e) {
//     print('Error sending message: $e');
//     throw Exception('Failed to send message');
//   }
// }

//   Future<String?> getChatRoom(String receiverId) async {
//   final currentUser = _auth.currentUser;

//   if (currentUser != null) {
//     try {
//       final chatQuery = await _firestore
//           .collection('chats')
//           .where('users', isEqualTo: [currentUser.uid, receiverId])
//           .limit(1)
//           .get();

//       if (chatQuery.docs.isNotEmpty) {
//         return chatQuery.docs.first.id;
//       }
//     } catch (e) {
//       print('Error getting chat room: $e');
//     }
//   }
//   return null;
// }

// Future<String> getOrCreateChatRoom(String receiverId) async {
//   final currentUser = _auth.currentUser;

//   if (currentUser == null) {
//     throw Exception('Current User is null');
//   }

//   try {
//     // Önce mevcut sohbet odasını kontrol et
//     final existingChatQuery = await _firestore
//         .collection('chats')
//         .where('users', isEqualTo: [currentUser.uid, receiverId])
//         .limit(1)
//         .get();

//     if (existingChatQuery.docs.isNotEmpty) {
//       // Mevcut sohbet odası varsa, onun ID'sini döndür
//       return existingChatQuery.docs.first.id;
//     } else {
//       // Mevcut sohbet odası yoksa, yeni bir tane oluştur
//       final newChatRoom = await _firestore.collection('chats').add({
//         'users': [currentUser.uid, receiverId],
//         'lastMessage': '',
//         'timestamp': FieldValue.serverTimestamp(),
//       });
//       return newChatRoom.id;
//     }
//   } catch (e) {
//     print('Error in getOrCreateChatRoom: $e');
//     throw Exception('Failed to get or create chat room');
//   }
// }
}
