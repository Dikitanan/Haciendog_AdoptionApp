import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  Future addEmployeeDetails(
      Map<String, dynamic> employeeInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("Employee")
        .doc(id)
        .set(employeeInfoMap);
  }

  Future<Stream<QuerySnapshot>> getEmployeeDetails() async {
    return await FirebaseFirestore.instance.collection('Employee').snapshots();
  }

  Future<void> updateEmployeeDetails(
      String id, Map<String, dynamic> updatedInfoMap) async {
    await FirebaseFirestore.instance
        .collection("Employee")
        .doc(id)
        .update(updatedInfoMap);
  }

  Future<void> deleteEmployee(String id) async {
    await FirebaseFirestore.instance.collection("Employee").doc(id).delete();
  }
}

class AnimalDatabase {
  Future addAnimalDetails(Map<String, dynamic> animalInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("Animal")
        .doc(id)
        .set(animalInfoMap);
  }

  Future<Stream<QuerySnapshot>> getAnimalDetails() async {
    return await FirebaseFirestore.instance.collection('Animal').snapshots();
  }

  Future<void> updateAnimalDetails(
      String id, Map<String, dynamic> updatedInfoMap) async {
    await FirebaseFirestore.instance
        .collection("Animal")
        .doc(id)
        .update(updatedInfoMap);
  }

  Future<void> deleteAnimal(String id) async {
    await FirebaseFirestore.instance.collection("Animal").doc(id).delete();
  }
}
