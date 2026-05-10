import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../structures/remote_file.dart';
import '../structures/download_file.dart';

class CoordinatorClient {
  Future<List<RemoteFile>> listFiles({
    required String host,
    required int port,
    String? searchText,
  }) async {
    final _SocketProtocol socketProtocol = await _connect(host, port);
    try {
      if (searchText != null && searchText.isNotEmpty) {
        socketProtocol.sendLine('SEARCH_FILES $searchText');
      } else {
        socketProtocol.sendLine('LIST_FILES');
      }

      final String firstLine = await socketProtocol.readLine();
      final List<String> firstTokens = firstLine.split(' ');
      if (firstTokens.isEmpty || firstTokens.first != 'OK') {
        throw Exception(firstLine);
      }

      final int count =
      firstTokens.length > 1 ? int.tryParse(firstTokens[1]) ?? 0 : 0;
      final List<RemoteFile> files = <RemoteFile>[];
      for (int i = 0; i < count; i++) {
        final String line = await socketProtocol.readLine();
        files.add(_parseFileLine(line));
      }

      final String endLine = await socketProtocol.readLine();
      if (endLine != 'END_LIST' && endLine != 'END_SEARCH') {
        throw Exception('Expected END_LIST or END_SEARCH, got: $endLine');
      }
      return files;
    } finally {
      await socketProtocol.close();
    }
  }

  Future<Map<String, String>> uploadFile({
    required String host,
    required int port,
    required File file,
    required int chunkSize,
  }) async {
    final int fileSize = await file.length();
    final int chunkCount = (fileSize / chunkSize).ceil();
    final String fileName = file.path.split(Platform.pathSeparator).last;
    final _SocketProtocol socketProtocol = await _connect(host, port);
    try {
      socketProtocol.sendLine(
        'UPLOAD_INIT $fileName $fileSize $chunkSize $chunkCount',
      );

      final String initLine = await socketProtocol.readLine();
      final List<String> initTokens = initLine.split(' ');
      if (initTokens.length < 3 || initTokens.first != 'OK') {
        throw Exception('UPLOAD_INIT failed: $initLine');
      }
      final String uploadId = initTokens[1];

      final Set<int> plannedChunks = <int>{};
      while (true) {
        final String line = await socketProtocol.readLine();
        if (line == 'END_PLAN') {
          break;
        }
        final List<String> tokens = line.split(' ');
        if (tokens.length < 2 || tokens.first != 'CHUNK') {
          throw Exception('Unexpected plan line: $line');
        }
        plannedChunks.add(int.parse(tokens[1]));
      }

      for (int index = 0; index < chunkCount; index++) {
        if (!plannedChunks.contains(index)) {
          throw Exception('Missing chunk plan for chunk $index');
        }
        final int start = index * chunkSize;
        final int end =
        (start + chunkSize > fileSize) ? fileSize : (start + chunkSize);
        final Uint8List chunk = await _readFileRange(file, start, end);
        socketProtocol
            .sendLine('UPLOAD_CHUNK $uploadId $index ${chunk.length}');
        socketProtocol.sendBytes(chunk);
        final String chunkAck = await socketProtocol.readLine();
        if (!chunkAck.startsWith('OK')) {
          throw Exception('Chunk upload failed for chunk $index: $chunkAck');
        }
      }

      socketProtocol.sendLine('UPLOAD_FINISH $uploadId');
      final String finishLine = await socketProtocol.readLine();
      final List<String> finishTokens = finishLine.split(' ');
      if (finishTokens.length < 2 || finishTokens.first != 'OK') {
        throw Exception('UPLOAD_FINISH failed: $finishLine');
      }
      return {
        'fileId': finishTokens[1],
        'shareUrl': finishTokens.length > 2 ? finishTokens[2] : '',
      };
    } finally {
      await socketProtocol.close();
    }
  }

  Future<DownloadedFile> downloadByFileId({
    required String host,
    required int port,
    required String fileId,
  }) {
    return _downloadCommon(
      host: host,
      port: port,
      command: 'DOWNLOAD $fileId',
    );
  }

  Future<DownloadedFile> downloadByShare({
    required String host,
    required int port,
    required String tokenOrUrl,
  }) {
    return _downloadCommon(
      host: host,
      port: port,
      command: 'DOWNLOAD_SHARE $tokenOrUrl',
    );
  }

  Future<DownloadedFile> _downloadCommon({
    required String host,
    required int port,
    required String command,
  }) async {
    final _SocketProtocol socketProtocol = await _connect(host, port);
    try {
      socketProtocol.sendLine(command);
      final String header = await socketProtocol.readLine();
      final List<String> tokens = header.split(' ');
      if (tokens.length < 5 || tokens.first != 'OK') {
        throw Exception(header);
      }

      final int fileSize = int.parse(tokens[tokens.length - 3]);
      final int chunkCount = int.parse(tokens[tokens.length - 1]);
      final String fileName = tokens.sublist(1, tokens.length - 3).join(' ');

      final Map<int, Uint8List> chunks = <int, Uint8List>{};
      while (true) {
        final String line = await socketProtocol.readLine();
        if (line == 'END_FILE') {
          break;
        }
        final List<String> chunkTokens = line.split(' ');
        if (chunkTokens.length != 3 || chunkTokens.first != 'CHUNK') {
          throw Exception('Unexpected stream line: $line');
        }
        final int index = int.parse(chunkTokens[1]);
        final int bytes = int.parse(chunkTokens[2]);
        chunks[index] = await socketProtocol.readBytes(bytes);
      }

      if (chunks.length != chunkCount) {
        throw Exception('Expected $chunkCount chunks, got ${chunks.length}');
      }

      final BytesBuilder builder = BytesBuilder(copy: false);
      for (int i = 0; i < chunkCount; i++) {
        final Uint8List? chunk = chunks[i];
        if (chunk == null) {
          throw Exception('Missing chunk $i');
        }
        builder.add(chunk);
      }
      final Uint8List allData = builder.toBytes();
      if (allData.length != fileSize) {
        throw Exception(
            'Size mismatch. Expected $fileSize, got ${allData.length}');
      }
      return DownloadedFile(
          fileName: fileName, fileSize: fileSize, data: allData);
    } finally {
      await socketProtocol.close();
    }
  }

  Future<_SocketProtocol> _connect(String host, int port) async {
    final Socket socket = await Socket.connect(host, port,
        timeout: const Duration(seconds: 8));
    return _SocketProtocol(socket);
  }

  Future<Uint8List> _readFileRange(File file, int start, int end) async {
    final Completer<Uint8List> completer = Completer<Uint8List>();
    final BytesBuilder builder = BytesBuilder(copy: false);
    file.openRead(start, end).listen(
      builder.add,
      onDone: () => completer.complete(builder.toBytes()),
      onError: completer.completeError,
      cancelOnError: true,
    );
    return completer.future;
  }

  RemoteFile _parseFileLine(String line) {
    final List<String> tokens = line.split(' ');
    if (tokens.length < 6 || tokens.first != 'FILE') {
      throw Exception('Unexpected FILE line: $line');
    }
    final String fileId = tokens[1];
    final int fileSize = int.parse(tokens[tokens.length - 3]);
    final int chunkCount = int.parse(tokens[tokens.length - 2]);
    final String shareUrl = tokens.last;
    final String fileName = tokens.sublist(2, tokens.length - 3).join(' ');
    return RemoteFile(
      fileId: fileId,
      fileName: fileName,
      fileSize: fileSize,
      chunkCount: chunkCount,
      shareUrl: shareUrl,
    );
  }
}

class _SocketProtocol {
  _SocketProtocol(this._socket);

  final Socket _socket;
  final List<int> _buffer = <int>[];
  StreamSubscription<List<int>>? _subscription;
  final Queue<Completer<void>> _waiters = Queue<Completer<void>>();
  bool _isDone = false;

  Future<void> _ensureListener() async {
    _subscription ??= _socket.listen(
          (List<int> data) {
        _buffer.addAll(data);
        while (_waiters.isNotEmpty) {
          _waiters.removeFirst().complete();
        }
      },
      onDone: () {
        _isDone = true;
        while (_waiters.isNotEmpty) {
          _waiters.removeFirst().complete();
        }
      },
      onError: (Object error) {
        _isDone = true;
        while (_waiters.isNotEmpty) {
          _waiters.removeFirst().completeError(error);
        }
      },
      cancelOnError: true,
    );
  }

  void sendLine(String line) {
    _socket.add(utf8.encode('$line\n'));
  }

  void sendBytes(Uint8List bytes) {
    _socket.add(bytes);
  }

  Future<String> readLine() async {
    await _ensureListener();
    while (true) {
      for (int i = 0; i < _buffer.length; i++) {
        if (_buffer[i] == 10) {
          final Uint8List lineBytes = Uint8List.fromList(_buffer.sublist(0, i));
          _buffer.removeRange(0, i + 1);
          return utf8.decode(lineBytes).trimRight();
        }
      }
      if (_isDone) {
        throw Exception('Connection closed while waiting line');
      }
      final Completer<void> waiter = Completer<void>();
      _waiters.add(waiter);
      await waiter.future;
    }
  }

  Future<Uint8List> readBytes(int length) async {
    await _ensureListener();
    while (true) {
      if (_buffer.length >= length) {
        final Uint8List bytes = Uint8List.fromList(_buffer.sublist(0, length));
        _buffer.removeRange(0, length);
        return bytes;
      }
      if (_isDone) {
        throw Exception('Connection closed while waiting $length bytes');
      }
      final Completer<void> waiter = Completer<void>();
      _waiters.add(waiter);
      await waiter.future;
    }
  }

  Future<void> close() async {
    await _subscription?.cancel();
    await _socket.flush();
    await _socket.close();
  }
}
