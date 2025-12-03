import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:docuverse/shared/models/models.dart';

class CollaborationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';
  String get currentUserName => _auth.currentUser?.displayName ?? '';
  String get currentUserEmail => _auth.currentUser?.email ?? '';

  // User Management
  Future<void> createUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      final userModel = UserModel(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoURL: user.photoURL,
        createdAt: DateTime.now(),
        lastSeen: DateTime.now(),
        isOnline: true,
      );
      await _firestore.collection('users').doc(user.uid).set(userModel.toFirestore());
    }
  }

  Future<void> updateUserOnlineStatus(bool isOnline) async {
    if (currentUserId.isEmpty) return;
    await _firestore.collection('users').doc(currentUserId).update({
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(DateTime.now()),
    });
  }

  Stream<List<UserModel>> getAllUsers() {
    if (currentUserEmail.isEmpty) {
      return Stream.value([]);
    }
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .where((user) => user.email != currentUserEmail && user.id != currentUserId)
            .toList()..sort((a, b) => a.displayName.compareTo(b.displayName)));
  }

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty || currentUserEmail.isEmpty) return [];
    
    final snapshot = await _firestore
        .collection('users')
        .get();
    
    return snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .where((user) => 
            user.email != currentUserEmail &&
            (user.displayName.toLowerCase().contains(query.toLowerCase()) ||
            user.email.toLowerCase().contains(query.toLowerCase())))
        .toList();
  }

  // Friend Request Management
  Future<void> sendFriendRequest(String receiverId, String receiverName, String receiverEmail) async {
    if (currentUserId.isEmpty || receiverId == currentUserId) return;

    try {
      // Check if they are already friends
      final alreadyFriends = await areFriends(receiverId);
      if (alreadyFriends) {
        throw Exception('You are already friends with this user');
      }

      // Check if request already exists (both directions)
      final existingRequest = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: currentUserId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        throw Exception('Friend request already sent');
      }

      // Check if there's a pending request from the other user
      final reverseRequest = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: receiverId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (reverseRequest.docs.isNotEmpty) {
        throw Exception('This user has already sent you a friend request. Check your notifications.');
      }

      final request = FriendRequestModel(
        id: '',
        senderId: currentUserId,
        receiverId: receiverId,
        senderName: currentUserName,
        senderEmail: currentUserEmail,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('friendRequests').add(request.toFirestore());
    } catch (e) {
      print('Error sending friend request: $e');
      rethrow;
    }
  }

  Stream<List<FriendRequestModel>> getReceivedFriendRequests() {
    if (currentUserId.isEmpty) {
      return Stream.value([]);
    }
    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequestModel.fromFirestore(doc))
            .toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Future<void> respondToFriendRequest(String requestId, bool accept) async {
    try {
      final requestDoc = await _firestore.collection('friendRequests').doc(requestId).get();
      if (!requestDoc.exists) throw Exception('Request not found');

      final request = FriendRequestModel.fromFirestore(requestDoc);
      
      // Use batch write for atomic operations
      final batch = _firestore.batch();
      
      if (accept) {
        // Create friendship for both users
        final user1FriendRef = _firestore
            .collection('users')
            .doc(request.senderId)
            .collection('friends')
            .doc(request.receiverId);
        
        final user2FriendRef = _firestore
            .collection('users')
            .doc(request.receiverId)
            .collection('friends')
            .doc(request.senderId);
        
        batch.set(user1FriendRef, {
          'friendId': request.receiverId,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });
        
        batch.set(user2FriendRef, {
          'friendId': request.senderId,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      
      // Update request status
      final requestRef = _firestore.collection('friendRequests').doc(requestId);
      batch.update(requestRef, {
        'status': accept ? 'accepted' : 'rejected',
        'respondedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      await batch.commit();
    } catch (e) {
      print('Error in respondToFriendRequest: $e');
      rethrow;
    }
  }

  Stream<List<UserModel>> getFriends() {
    if (currentUserId.isEmpty) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .snapshots()
        .asyncMap((snapshot) async {
      List<UserModel> friends = [];
      
      // Use Future.wait for better performance
      final friendFutures = snapshot.docs.map((doc) async {
        try {
          final friendDoc = await _firestore.collection('users').doc(doc.id).get();
          if (friendDoc.exists) {
            return UserModel.fromFirestore(friendDoc);
          }
        } catch (e) {
          print('Error fetching friend ${doc.id}: $e');
        }
        return null;
      });
      
      final results = await Future.wait(friendFutures);
      friends = results.where((friend) => friend != null).cast<UserModel>().toList();
      
      // Sort friends by online status and name
      friends.sort((a, b) {
        if (a.isOnline && !b.isOnline) return -1;
        if (!a.isOnline && b.isOnline) return 1;
        return a.displayName.compareTo(b.displayName);
      });
      
      return friends;
    });
  }

  // Chat Management
  Future<String> createOrGetChat(String friendId, String friendName) async {
    final participants = [currentUserId, friendId]..sort();
    final chatId = participants.join('_');

    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    
    if (!chatDoc.exists) {
      final chat = ChatModel(
        id: chatId,
        participants: participants,
        participantNames: {
          currentUserId: currentUserName,
          friendId: friendName,
        },
        createdAt: DateTime.now(),
        unreadCount: {currentUserId: 0, friendId: 0},
      );
      await _firestore.collection('chats').doc(chatId).set(chat.toFirestore());
    }
    
    return chatId;
  }

  Stream<List<ChatModel>> getUserChats() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromFirestore(doc))
            .toList());
  }

  Future<void> sendMessage(String chatId, String content, {MessageType type = MessageType.text, String? fileUrl, String? fileName, String? fileType}) async {
    final message = ChatMessageModel(
      id: '',
      chatId: chatId,
      senderId: currentUserId,
      senderName: currentUserName,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      fileUrl: fileUrl,
      fileName: fileName,
      fileType: fileType,
    );

    await _firestore.collection('messages').add(message.toFirestore());

    // Update chat with last message
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': content,
      'lastMessageTime': Timestamp.fromDate(DateTime.now()),
      'lastMessageSender': currentUserId,
    });
  }

  Stream<List<ChatMessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromFirestore(doc))
            .toList());
  }

  Future<bool> areFriends(String userId) async {
    if (currentUserId.isEmpty || userId == currentUserId) return false;
    
    try {
      final friendDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(userId)
          .get();
      
      return friendDoc.exists;
    } catch (e) {
      print('Error checking friendship status: $e');
      return false;
    }
  }

  Future<bool> hasPendingRequest(String userId) async {
    if (currentUserId.isEmpty || userId == currentUserId) return false;
    
    try {
      final request = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: currentUserId)
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      return request.docs.isNotEmpty;
    } catch (e) {
      print('Error checking pending request: $e');
      return false;
    }
  }

  Future<bool> hasIncomingRequest(String userId) async {
    if (currentUserId.isEmpty || userId == currentUserId) return false;
    
    try {
      final request = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: userId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();
      return request.docs.isNotEmpty;
    } catch (e) {
      print('Error checking incoming request: $e');
      return false;
    }
  }

  Stream<int> getFriendRequestCount() {
    if (currentUserId.isEmpty) return Stream.value(0);
    
    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          print('Friend request count for $currentUserId: ${snapshot.docs.length}');
          return snapshot.docs.length;
        });
  }

  // Debug method to check user's friend requests
  Future<void> debugFriendRequests() async {
    if (currentUserId.isEmpty) {
      print('DEBUG: No current user');
      return;
    }
    
    print('DEBUG: Current user ID: $currentUserId');
    print('DEBUG: Current user name: $currentUserName');
    print('DEBUG: Current user email: $currentUserEmail');
    
    // Check sent requests
    final sentRequests = await _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: currentUserId)
        .get();
    
    print('DEBUG: Sent requests: ${sentRequests.docs.length}');
    for (var doc in sentRequests.docs) {
      final data = doc.data();
      print('  - To: ${data['receiverId']} (${data['senderName']}) - Status: ${data['status']}');
    }
    
    // Check received requests
    final receivedRequests = await _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: currentUserId)
        .get();
    
    print('DEBUG: Received requests: ${receivedRequests.docs.length}');
    for (var doc in receivedRequests.docs) {
      final data = doc.data();
      print('  - From: ${data['senderId']} (${data['senderName']}) - Status: ${data['status']}');
    }
    
    // Check friends
    final friends = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .get();
    
    print('DEBUG: Friends: ${friends.docs.length}');
    for (var doc in friends.docs) {
      print('  - Friend ID: ${doc.id}');
    }
  }






}