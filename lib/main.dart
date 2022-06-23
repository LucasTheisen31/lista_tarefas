
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; //Um plugin Flutter para encontrar locais comumente usados no sistema de arquivos

///Material é responsável por estilizar os widgets de interface com base nos padrões do Material Design

void main() {
  runApp(MaterialApp(
    home: Home(), //cria uma tela home
  ));
}

///Basicamente, um widget é um componente visual para definir a interface de um aplicativo.
///Cada widget é uma pequena peça e, ao final, este conjunto de peças representará uma interface completa:
///cria tela home como um widget stateful
class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _controladorToDo = TextEditingController();
  List _toDoList=[]; //lista que vai armazenar as tarefas

  Map<String, dynamic> ?_ultimoRemovido; //mapa de string para pegar os items removidos
  int ?_posicaoUltimoRemovido; //para pegar a posicao do item removido

  @override
  void initState() {//metodo que é executado ao iniciamos o estado do widget
    super.initState();
    _readData().then((data){//vai chamar a funcao readData que vai retornar uma String com todos os registros e essa string vai ser passada para a variavel data
      setState(() {//atualiza a tela ao executar o comando abaixo
        _toDoList = jsonDecode(data); //pega a string"data" do arquivo e da um jsonDecode para a _todoList
      });
    });
  }


  void adicionartoDo(){
    setState(() { //setState atualiza a tela ao executar estes comandos
      Map<String, dynamic> novoToDo = new Map();
      novoToDo["title"] = _controladorToDo.text;//armazena o dado pego no text field
      novoToDo["ok"] = false;
      _controladorToDo.text = "";//limpa o campo de texto
      _toDoList.add(novoToDo); //adiciona na lista
      _saveData();//salva os dados no arquivo
    });
  }

 Future<Null> _atualizar() async{// funcao vai ser assincrona ou seja nao vai executar imediatamente
    await Future.delayed(Duration(seconds: 1)); //vai agardar 1 segundo
   //apos esperar 1 segundo vamos ordenar os dados
   setState(() {//atualiza a tela ao executar o comando
     _toDoList.sort((a, b){
       if(a["ok"] && !b["ok"]){
         return 1;
       }
       else if(!a["ok"] && b["ok"]){
         return -1;
       }
       else {
         return 0;
       }
     });
     _saveData();//salva a List _toDoList atualizada
   });
   return null;
 }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Aplicativo de Tarefas"),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Column(//adiciona uma coluna ao corpo da janela
        children:<Widget> [
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1), //adiciona margem
            child: Row( //adiciona uma linha no container
              children:<Widget> [
                Expanded(
                    child: TextField(
                      controller: _controladorToDo,//variavel que vai pegar os dados do text feld
                      decoration: InputDecoration(
                          labelText: "Nova Tarefa",
                          labelStyle: TextStyle(color: Colors.blue)
                      ),
                    ),),
                ElevatedButton(
                  child: Text('ADD'),
                  onPressed: adicionartoDo,
                  style: ElevatedButton.styleFrom(
                      primary: Colors.blue
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(//widget que suporta o "deslizar para atualizar"
              onRefresh: _atualizar,//acao executada ao "deslizar para atualizar" (onRefresh)
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10),
                itemCount: _toDoList.length,//tamanho da lista ou numero de itens da lista
                itemBuilder: buildItem,//chama a funcao que vai retornar um widget deslizavel que sera um CheckboxListTile
              ),
            )
          ),
        ],
      ),
    );
  }

  Widget buildItem(context, index){//index é o elemento da lista que ta sendo desenhado, ou seja a posicao na lista
    return Dismissible( //Dismissible é um widget que pode arrastar
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),//pois nexessita de uma key que seja uma string entao vamos transformar o tempo em string
      background: Container(
        color: Colors.red,//quando deslizar vai aparecer um funco vermelho
        child: (Align(//para alinhar o icone que sera adicionado
          alignment: Alignment(-0.9, 0),//vai alinhar o icone a esquerda e 0 em y
          child: Icon(Icons.delete, color: Colors.white,),//vai adicionar o icone
        )),
      ),
      direction: DismissDirection.startToEnd,//define a direcao que vai deslizar o widget(no caso da esquerda para a direita
      child: CheckboxListTile(//define qual vai ser o widget no caso vai ser um checkboxListTitle
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"]? Icons.check : Icons.error),
        ),
        onChanged:(bool){
          setState(() {//atualiza a tela ao executar o comando
            _toDoList[index]["ok"] = bool;//toDoList na posicao index - ok recebe bool
            _saveData();//salva os dados no arquivo
          });
        },
      ),
      onDismissed: (direction){//acao executada ao arrastar o widget, e precisamos passar a direçao que sera arrastado para executar esta ação
        setState(() {//para atualizar na tela ao executar os comandos a baixo
          _ultimoRemovido = Map.from(_toDoList[index]);//ultimoRemovido vai armazenar o dado removido
          _posicaoUltimoRemovido = index; //armazena o indice da posicao que foi removido
          _toDoList.removeAt(index);//remove o item da list _toDoList na posicao index

          _saveData();//salva a list _toDoList com o dado removido

          //agora qeremos que apareca uma snackBar
          final snack = SnackBar(
              content: Text("Tarefa ${_ultimoRemovido!["title"]} removido"), //definindo o conteudo da snackBar
              action: SnackBarAction( //define uma açao para a snackBar
                  label: "Desfazer",
                  onPressed: (){
                    setState(() { //atualiza na tela ao executar os comandos a baixo
                      _toDoList.insert(_posicaoUltimoRemovido!, _ultimoRemovido);//insere o dado removido novamente na list _toDoList
                      _saveData();//salva a list _toDoList com o dado removido
                    });
                  },
              ),
            duration: Duration(seconds: 2) //define 2 segundos de duraçao para o snackBar
          );
          ScaffoldMessenger.of(context).showSnackBar(snack); //para exibir a nackBar
        });
      },
    );
  }

  //funcao que vai retornar o arquivos que vamos usar para salvar
  Future<File> _getFile() async {
    final diretorio = await getApplicationDocumentsDirectory(); //vai pegar o diretorio onde podemos armazenar os documentos do app
    return File("${diretorio.path}/data.json"); //retorna o arquivo com o caminho do diretorio
  }

  //funcao para salvar os dados
  Future<File> _saveData() async{
    String data = json.encode(_toDoList); //transforma a lista em um JSON e armazena na string data
    // JSON que significa JavaScript Object Notation, é uma formatação utilizada para estruturar dados em formato de texto e transmiti-los de um sistema para outro
    final file = await _getFile(); //chama a funcao _getFile() que retorna o arquivo com o caminho onde vamos salvar

    return file.writeAsString(data); //escreve os dados da lista _toDoList em forma de texto dentro do arquivo, lembrando que o arquivo tambem contem o caminho onde vamos salvar
  }

  //funcao para ler os dados
  Future<String> _readData() async{
    try{
      final file = await _getFile();//tenta pegar o arquivo com os dados
      return file.readAsString();//le os dados do arquivo como string
    }catch(e){
      return "null";
    }
  }
}

