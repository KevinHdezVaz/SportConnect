// lib/widgets/chat_tab.dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:user_auth_crudd10/model/ChatMessage.dart';
import 'package:user_auth_crudd10/services/chatEquipo_service.dart';

class ChatTab extends StatefulWidget {
  final int equipoId;
  final int userId;

  const ChatTab({required this.equipoId, required this.userId, Key? key})
      : super(key: key);

  @override
  _ChatTabState createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
    ChatMessage? replyingTo;  // Mensaje al que se está respondiendo

  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> messages = [];
  bool isLoading = true;
  final FocusNode _focusNode = FocusNode(); // Agregar esto

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
    _loadMessages();
  }

 
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose(); // No olvides disponer el FocusNode
    super.dispose();
  }
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        _sendFileMessage(file, 'archivo');
      }
    } catch (e) {
      _showErrorSnackBar('Error al seleccionar archivo: $e');
    }
  }



  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final newMessage = await _chatService.sendMessage(
        widget.equipoId,
        widget.userId,
        _messageController.text,
        replyToId: replyingTo?.id,  // Agregar ID del mensaje al que se responde
      );

      setState(() {
        messages.add(newMessage);
        _messageController.clear();
        replyingTo = null;  // Limpiar el mensaje de respuesta
      });
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar el mensaje: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (photo != null) {
        File file = File(photo.path);
        _sendFileMessage(file, 'imagen');
      }
    } catch (e) {
      _showErrorSnackBar('Error al tomar foto: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        File file = File(image.path);
        _sendFileMessage(file, 'imagen');
      }
    } catch (e) {
      _showErrorSnackBar('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _sendFileMessage(File file, String type) async {
    try {
      final newMessage = await _chatService.sendFile(
        widget.equipoId,
        widget.userId,
        file,
        type,
      );

      setState(() {
        messages.add(newMessage);
      });
      _scrollToBottom();
    } catch (e) {
      _showErrorSnackBar('Error al enviar el archivo: $e');
    }
  }

 Future<void> _loadMessages() async {
  setState(() => isLoading = true);
  try {
    final loadedMessages = await _chatService.getMessages(widget.equipoId);
    setState(() {
      messages = loadedMessages.reversed.toList(); // Invertir orden
      isLoading = false;
    });
    _scrollToBottom();
  } catch (e) {
    setState(() => isLoading = false);
    _showErrorSnackBar('Error al cargar los mensajes: $e');
  }
}

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadMessages,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
                ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: Icon(Icons.attach_file),
              title: Text('Documento'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 1),
            blurRadius: 3,
            color: Colors.black12,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: Text('FP', style: TextStyle(color: Colors.white)),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chat del Equipo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${messages.length} mensajes',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    bool isMe = message.userId == widget.userId;
    return Slidable(
      enabled: !isMe,  // Solo permite deslizar mensajes de otros usuarios
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              setState(() {
                replyingTo = message;
              });
              // Enfocar el campo de texto
              FocusScope.of(context).requestFocus(_focusNode);
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.reply,
            label: 'Responder',
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) _buildAvatar(message),
            if (!isMe) SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (message.replyTo != null)
                    _buildReplyPreview(message.replyTo!, isMe),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? Theme.of(context).primaryColor : Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    child: _buildMessageContent(message, isMe),
                  ),
                ],
              ),
            ),
            if (isMe) SizedBox(width: 8),
            if (isMe) _buildAvatar(message),
          ],
        ),
      ),
    );
  }

Widget _buildMessageContent(ChatMessage message, bool isMe) {
  return Column(
    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
      Text(
        message.userName,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isMe ? Colors.white : Colors.black87,
          fontSize: 13,
        ),
      ),
      SizedBox(height: 4),
      if (message.message.isNotEmpty) ...[
        Text(
          message.message,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
        SizedBox(height: 4),
      ],
      if (message.fileUrl != null && message.fileType == 'imagen')
        GestureDetector(
          onTap: () => _showFullImage(context, message.fileUrl!),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 150,
                maxWidth: 200,
              ),
              child: CachedNetworkImage(
                imageUrl: 'https://proyect.aftconta.mx${message.fileUrl}',
                placeholder: (context, url) => Container(
                  height: 150,
                  width: 200,
                  color: Colors.grey[300],
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 150,
                  width: 200,
                  color: Colors.grey[300],
                  child: Icon(Icons.error),
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      SizedBox(height: 2),
      Text(
        timeago.format(message.createdAt, locale: 'es'),
        style: TextStyle(
          color: isMe 
              ? Colors.white.withOpacity(0.7) 
              : Colors.grey[600],
          fontSize: 11,
        ),
      ),
    ],
  );
}


  Widget _buildReplyPreview(ChatMessage repliedMessage, bool isMe) {
    return Container(
      margin: EdgeInsets.only(bottom: 4),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe 
            ? Colors.blue.withOpacity(0.1) 
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: Colors.blue,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            repliedMessage.userName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 2),
          Text(
            repliedMessage.message,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildReplyBar() {
    if (replyingTo == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            color: Colors.blue,
            margin: EdgeInsets.only(right: 8),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Respondiendo a ${replyingTo!.userName}',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  replyingTo!.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              setState(() {
                replyingTo = null;
              });
            },
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: 'https://proyect.aftconta.mx$imageUrl',
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.error,
                  color: Colors.white,
                ),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Widget _buildAvatar(ChatMessage message) {
    // Construir la URL completa para la imagen de perfil
    String? imageUrl = message.userImage != null
        ? 'https://proyect.aftconta.mx/storage/${message.userImage}'
        : null;

    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey[300],
      backgroundImage:
          imageUrl != null ? CachedNetworkImageProvider(imageUrl) : null,
      child: imageUrl == null
          ? Text(
              message.userName[0].toUpperCase(),
              style: TextStyle(color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -2),
            blurRadius: 4,
            color: Colors.black12,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.attach_file, color: Colors.grey[600]),
              onPressed: _showAttachmentOptions,
            ),
            IconButton(
              icon: Icon(Icons.camera_alt, color: Colors.grey[600]),
              onPressed: _takePhoto,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,  
                decoration: InputDecoration(
                  hintStyle: TextStyle(color: Colors.black),
                  hintText: 'Escribe un mensaje...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.send,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
