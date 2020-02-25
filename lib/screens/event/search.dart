import 'package:Solon/screens/error_screen.dart';
import 'package:Solon/util/user_util.dart';
import 'package:Solon/widgets/cards/event_card.dart';
import 'package:flutter/material.dart';
import 'package:Solon/models/event.dart';
import 'package:Solon/util/app_localizations.dart';
import 'package:Solon/util/event_util.dart';

class EventsSearch extends SearchDelegate {
  BuildContext context;

  EventsSearch(this.context);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty)
      showSuggestions(
          context); // TODO: make keyboard unfocus cleaner when searching with empty query
    UserUtil.cacheSearchQuery(Event, query);
    return StreamBuilder<List<Event>>(
      stream: Function.apply(
        EventUtil.searchView,
        [
          query,
        ],
      ),
      builder: (BuildContext context, AsyncSnapshot<List<Event>> snapshot) {
        if (snapshot.hasError) return Text('Error: ${snapshot.error}');
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return Center(
              child: CircularProgressIndicator(),
            );
          default:
            if (snapshot.data == null) {
              return ErrorScreen();
            }
            return ListView(
                children: snapshot.data
                    .map((json) => EventCard(event: json))
                    .toList());
        }
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder(
      // TODO: can be abstracted
      future: UserUtil.getCachedSearches(Event),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.none &&
            snapshot.hasData == null) {
          return Container();
        }
        return ListView.builder(
          itemCount: snapshot.data.length,
          itemBuilder: (context, index) {
            print(snapshot.data.toString());
            return ListTile(
              title: Text('${snapshot.data[index]}'),
              onTap: () => {
                query = snapshot.data[index],
                showResults(context),
              },
            );
          },
        );
      },
    );
  }

  @override
  String get searchFieldLabel =>
      AppLocalizations.of(context).translate("searchEvents");
}
