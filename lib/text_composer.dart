import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TextComposer extends StatefulWidget {
  // essa linha declara o construtor da classe TextComposer com dois
  // parâmetros nomeados: key e sendMessage. O parâmetro
  // sendMessage é obrigatório (requerido) e deve ser fornecido
  // ao criar uma instância de TextComposer. A chave fornecida
  // é usada para associar uma chave única ao widget, se necessário.
  const TextComposer({Key? key, required this.sendMessage}) : super(key: key);


  final Function({String?  text, File? imgFile})? sendMessage; //armazenar uma referência para uma função que aceita um parâmetro nomeado chamado text

  @override
  State<TextComposer> createState() => _TextComposerState();
}

class _TextComposerState extends State<TextComposer> {
  //função para acessar o texto
  final TextEditingController _controller = TextEditingController();

  bool _isComposing = false;

  //funão para limpar campos
  void _reset() {
    _controller.clear();
    setState(() {
      //desabilita o botao de enviar
      _isComposing = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: <Widget>[
          IconButton(
            //Onde iremos tratar o botão da camera
              onPressed: () async{
              final XFile? imgFile =
                await ImagePicker().pickImage(source: ImageSource.camera);
              if (imgFile == null){
                return;
                }
              File fileSend = File(imgFile.path);
              widget.sendMessage!(imgFile: fileSend);
              },
              icon: Icon(Icons.photo_camera),
          ),
          Expanded(//Ocupa o maior espaço possivel
              child: TextField(
                //onde iremos tratar o botão de enviar texto
                controller: _controller,
                decoration:
                  const InputDecoration.collapsed(hintText: "Enviar uma mensagem"),
                onChanged: (text){
                  setState(() {
                    _isComposing = text.isNotEmpty;
                  });
                },
                onSubmitted: (text){
                  widget.sendMessage!(text: text);
                  _reset();
                },
              ),
          ),
          IconButton(
            //verificação do botao enviar Desabilitado/Habilitado
              onPressed: _isComposing ? (){
                widget.sendMessage!(text: _controller.text);
                _reset();
              } : null,
              icon: Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
