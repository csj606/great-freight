import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'home_page.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: const MyHomePage(title: 'GreatFreight Login'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController name = TextEditingController();
  FirebaseFirestore db = FirebaseFirestore.instance;
  bool amDriver = false;
  bool amMerchant = false;

  String errorMessage = "";

  void createNewUser() async{
    try{
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: usernameController.text,
          password: passwordController.text
      );
      String userType = "";
      if(amDriver){
        userType = "driver";
      }else{
        userType = "merchant";
      }
      final user = <String, dynamic>{
        "email" : usernameController.text,
        "userType" : userType,
        "name": name.text,
        "isMerchant": amMerchant,
        "isDriver": amDriver,
      };
      db.collection("users").doc(usernameController.text).set(user);
      Navigator.push(context, MaterialPageRoute(
          builder: (context) => HomePage(cred)
      ));
    }on FirebaseAuthException catch (error){
      if(error.code == "email-already-in-use"){
        setState(() {
          errorMessage = "This email is already in use";
        });
      }else if(error.code == "invalid-email"){
        setState(() {
          errorMessage = "This email is not a valid email address";
        });
      }else if(error.code == "weak-password"){
        setState(() {
          errorMessage = "Please choose a stronger password";
        });
      }else if(error.code == "network-request-failed"){
        setState(() {
          errorMessage = "There is currently no internet - try again later";
        });
      }
    }catch (error){
      setState(() {
        errorMessage = error.toString();
      });
    }
  }

  void loginUser() async{
    try{
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: usernameController.text,
          password: passwordController.text
      );
      Navigator.push(context, MaterialPageRoute(
          builder: (context) => HomePage(cred)
      ));
    } on FirebaseAuthException catch (error){
      print(error.code);
      if(error.code == "invalid-credential"){
        setState(() {
          errorMessage = "Email or password is incorrect, create a new account if you haven't already";
        });
      }else if(error.code == "user-not-found"){
        setState(() {
          errorMessage = "Please create a new account before logging in";
        });
      }
    } catch (error){
      setState(() {
        errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
                flex: 14,
                child: TextField(
                  controller: usernameController,
                  onSubmitted: (String user) { setState(() {
                    usernameController.text = user;
                  });},
                  decoration: InputDecoration(
                      labelText: "   Email"
                  ),
                )
            ),
            Expanded(
                flex: 14,
                child: TextField(
                    controller: passwordController,
                    onSubmitted: (String password) {
                      setState(() {
                        passwordController.text = password;
                      });
                    },
                    decoration: InputDecoration(
                        labelText: "   Password"
                    )
                )
            ),
            Expanded(
              flex: 12,
              child: ElevatedButton(
                  onPressed: loginUser,
                  child: Text("Login to Existing Account")
              ),
            ),
            Expanded(
              flex: 12,
              child: TextField(
                  controller: name,
                  onSubmitted: (String enteredName) {
                    setState(() {
                      name.text = enteredName;
                    });
                  },
                  decoration: InputDecoration(
                      labelText: "   Name"
                  )
              ),
            ),
            Expanded(
                flex: 12,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: amMerchant,
                        onChanged: (bool? value){
                          if(amDriver){
                            setState(() {
                              errorMessage = "You cannot both be a driver and a merchant";
                            });
                          }else{
                            setState(() {
                              amMerchant = value!;
                            });
                          }
                        },
                      ),
                      Text("I am a merchant"),
                    ]
                )
            ),
            Expanded(
                flex: 12,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                          value: amDriver,
                          onChanged: (bool? value){
                            if(amMerchant){
                              setState(() {
                                errorMessage = "You cannot both be a driver and a merchant";
                              });
                            }else{
                              setState(() {
                                amDriver = value!;
                              });
                            }
                          }
                      ),
                      Text("I am a driver"),
                    ]
                )
            ),
            Expanded(
              flex: 12,
              child: ElevatedButton(
                  onPressed: (){
                    if(!amDriver && !amMerchant){
                      setState(() {
                        errorMessage = "You must select an account type";
                      });
                    }else if(name.text == ""){
                      setState(() {
                        errorMessage = "You must provide your name or the name of your company";
                      });
                    }else{
                      createNewUser();
                    }
                  },
                  child: Text("Create a New Account")
              ),
            ),
            Expanded(
              flex: 12,
              child: Text(errorMessage,
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold
                  )
              ),
            )
          ],
        ),
      ),
    );
  }
}
