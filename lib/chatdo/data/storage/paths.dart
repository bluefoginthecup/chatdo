
 import 'package:firebase_storage/firebase_storage.dart';
 
 abstract class UserStoragePaths {
   /// 이미지 루트: chat_images/{uid}/{messageId}
   Reference chatImagesRoot(String uid, String messageId);
 }
 
 /// V1: 현재 쓰는 폴더 구조
 class FirebaseStoragePathsV1 implements UserStoragePaths {
   final FirebaseStorage st;
   FirebaseStoragePathsV1(this.st);
   @override
   Reference chatImagesRoot(String uid, String messageId) =>
       st.ref('chat_images/$uid/$messageId');
 }
 
 /// 활성 버전 선택기 (나중에 바뀌면 여기만 교체)
 UserStoragePaths currentStoragePaths(FirebaseStorage st) =>
     FirebaseStoragePathsV1(st);
