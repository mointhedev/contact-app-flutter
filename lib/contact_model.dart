import 'dart:typed_data';

import 'package:contacts_service/contacts_service.dart';

class Contact {
  // Name
  String displayName, givenName, middleName, prefix, suffix, familyName;

// Company
  String company, jobTitle;

// Email addresses
  Iterable<Item> emails = [];

// Phone numbers
  Iterable<Item> phones = [];

// Post addresses
  Iterable<PostalAddress> postalAddresses = [];

// Contact avatar/thumbnail
  Uint8List avatar;
}
