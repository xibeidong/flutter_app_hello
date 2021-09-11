import 'package:flutter/material.dart';
import 'dart:math';
//编写第一个Flutter应用，https://flutterchina.club/get-started/codelab/

class RandomWords extends StatefulWidget {
  const RandomWords({Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => RandomState();
}

class RandomState extends State<RandomWords> {
  //final _suggestion = <int>[];
  //定义一个set
  final _saved = <int>{};
  final _biggerFont = const TextStyle(fontSize: 18);
  final _rng = Random();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RandomNum'),
        actions: <Widget>[
          IconButton(onPressed: _pushSaved, icon: const Icon(Icons.list))
        ],
      ),
      body: _buildSuggestions(),
    );
  }

  void _pushSaved() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      final tiles = _saved.map((nn) => ListTile(
            title: Text(
              nn.toString(),
              style: _biggerFont,
            ),
          ));
      // final ds = tiles.toList();
      //每个ListTile之间加个divide
      final divided =
          ListTile.divideTiles(tiles: tiles, context: context).toList();

      return Scaffold(
        appBar: AppBar(
          title: const Text('收藏'),
        ),
        body: ListView(
          children: divided,
        ),
      );
    }));
  }

  Widget _buildSuggestions() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, i) {
        //判断i是不是奇数
        if (i.isOdd) return const Divider();
        return _buildRow(_rng.nextInt(20));
      },
    );
  }

  Widget _buildRow(int i) {
    final _alreadySaved = _saved.contains(i);
    return ListTile(
      title: Text(i.toString(), style: _biggerFont),
      trailing: Icon(
        _alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: _alreadySaved ? Colors.red : null,
      ),
      onTap: () {
        setState(() {
          _alreadySaved ? _saved.remove(i) : _saved.add(i);
        });
      },
    );
  }
}
