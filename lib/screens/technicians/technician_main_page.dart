import 'package:flutter/material.dart';
import 'package:lapboost_admin_app/screens/settings_page.dart';
import 'package:lapboost_admin_app/screens/technicians/past_jobs_page.dart';
import 'package:mysql1/mysql1.dart';

import 'assigned_jobs_page.dart';

class TechnicianMainPage extends StatelessWidget {
  ResultRow user;
  TechnicianMainPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text('Welcome ${user['Employee_FirstName']}!'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Assigned Jobs'),
              Tab(text: 'Past Jobs'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AssignedJobsPage(
              user: user,
            ), // A page that lists the assigned jobs
            PastJobsPage(
              user: user,
            ), // A page that lists the past jobs
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => SettingsPage(user: user)));
          },
          child: const Icon(Icons.settings),
        ),
      ),
    );
  }
}
