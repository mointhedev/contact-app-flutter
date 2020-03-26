import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:simple_permissions/simple_permissions.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Contact List App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Contacts List'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoading = false;
  bool _errorOccurred = false;
  bool _havePermission = false;
  List<String> phoneNumbers = [];

  //For parsing each number
  Future<String> getPhoneNumber(String phoneNumber) async {
    try {
      PhoneNumber number = await PhoneNumber.getRegionInfoFromPhoneNumber(
          phoneNumber.toString());
      String parsableNumber = number?.parseNumber();
      return parsableNumber.toString();
    } catch (e) {
      print('Error while parsing ${e.toString()}');
      phoneNumber = phoneNumber
          .replaceAll('+', '')
          .replaceAll('-', '')
          .replaceAll('(', '')
          .replaceAll(')', '')
          .replaceFirst(' ', '|')
          .split('|')[1]
          .replaceAll(' ', '');
      return phoneNumber;
    }
  }

  @override
  void initState() {
    setState(() {
      _isLoading = true;
    });
    SimplePermissions.requestPermission(Permission.ReadContacts).then((status) {
      setState(() {
        _isLoading = true;
      });
      if (status != PermissionStatus.authorized) {
        debugPrint("no read rights. Aborting mission!");
        setState(() {
          _isLoading = false;
          _havePermission = false;
        });
        return;
      }

      //Getting Contacts
      debugPrint("start loading contacts");
      ContactsService.getContacts().then((foundContacts) {
        debugPrint("done loading contacts : Found contacts: " +
            foundContacts.length.toString());
        final list = foundContacts.toList();
        list.sort((a, b) => a.givenName.compareTo(b.givenName));

        List<String> numbers = [];
        List<String> unParsedNumbers = [];

        //Getting all the numbers inside list of contact
        list.forEach((element) {
          element.phones.forEach(
              (element) => unParsedNumbers.add(element.value.toString()));
        });

        //Function for parsing numbers and storing them in numbers list
        //and then in phoneNumbers list after completion
        parseContacts() async {
          print("start parsing");
          await Future.forEach(unParsedNumbers, (String number) async {
            final value = await getPhoneNumber(number);
            numbers.add(value);
          });
          print("end parsing");
          setState(() {
            phoneNumbers = List<String>.from(numbers);
            _isLoading = false;
            _havePermission = true;
          });
        }

        //Finally calling the above function
        parseContacts();
      }).catchError((error) {
        setState(() {
          _isLoading = false;
          _havePermission = false;
          _errorOccurred = true;
        });
        debugPrint(error.toString());
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : _errorOccurred || !_havePermission || phoneNumbers == null
                ? Center(
                    child: Text('Failed to load contacts'),
                  )
                : phoneNumbers.isEmpty
                    ? Center(
                        child: Text('No Contacts'),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListView(
                            children: phoneNumbers.map((phoneNum) {
                          return SelectableText(phoneNum.toString());
                        }).toList()),
                      )
        // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
