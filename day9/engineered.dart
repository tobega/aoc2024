import 'dart:io';
import 'dart:convert';
import 'dart:async';

class DiskFile {
  int id;
  int startBlock;
  int size;
  DiskFile(this.id, this.startBlock, this.size);

  @override
  String toString() => 'DiskFile(id: $id, startBlock: $startBlock, size: $size)';
}

class FreeBlock {
  int startBlock;
  int size;
  FreeBlock(this.startBlock, this.size);

  @override
  String toString() => 'FreeBlock(startBlock: $startBlock, size: $size)';
}

class FileSystem {
  List<List<FreeBlock>> freeBlocks = List.generate(10, (_) => <FreeBlock>[]);
  List<DiskFile> files = [];
  FileSystem();

  void addFile(DiskFile file) {
    files.add(file);
  }

  List<DiskFile> get fileList => List.from(files);

  void addFreeBlock(FreeBlock? freeBlock) {
    if (freeBlock == null || freeBlock.size == 0) {
      return;
    }
    freeBlocks[freeBlock.size].add(freeBlock);
    // TODO: merge adjacent free blocks. Not needed for AoC.
  }

  FreeBlock? removeLeftmostFreeBlock(int size) {
    FreeBlock? result = null;
    for (var validSize = size; validSize < 10; validSize++) {
      for (var freeBlock in freeBlocks[validSize]) {
        if (result == null || freeBlock.startBlock < result.startBlock) {
          result = freeBlock;
        }
      }
    }
    if (result != null) {
      freeBlocks[result.size].remove(result);
    }
    return result;
  }

  int checksum() {
    return files.fold(0, (sum, file) => sum + file.id * (2 * file.startBlock + file.size - 1) * file.size ~/ 2);
  }

  @override
  String toString() => 'FileSystem(files: $files, freeBlocks: $freeBlocks)';
}

int compact(FileSystem fileSystem) {
  fileSystem.fileList.reversed.forEach((file) {
    var size = file.size;
    do {
      var freeBlock = fileSystem.removeLeftmostFreeBlock(1);
      if (freeBlock != null && freeBlock.startBlock < file.startBlock) {
        if (freeBlock.size >= file.size) {
          fileSystem.addFreeBlock(FreeBlock((freeBlock.startBlock + file.size).toInt(), (freeBlock.size - file.size).toInt()));
          file.startBlock = freeBlock.startBlock;
        } else {
          var segment = DiskFile(file.id, freeBlock.startBlock, freeBlock.size);
          fileSystem.addFile(segment);
          file.size -= freeBlock.size;
        }
        size -= freeBlock.size;
        // TODO: return vacated space to freeBlocks
      } else {
        break;
      }
    } while (size > 0);
  });
  return fileSystem.checksum();
}

int compact2(FileSystem fileSystem) {
  fileSystem.fileList.reversed.forEach((file) {
    var freeBlock = fileSystem.removeLeftmostFreeBlock(file.size);
    if (freeBlock != null && freeBlock.startBlock < file.startBlock) {
      fileSystem.addFreeBlock(FreeBlock(file.startBlock, file.size));
      fileSystem.addFreeBlock(FreeBlock(freeBlock.startBlock + file.size, freeBlock.size - file.size));
      file.startBlock = freeBlock.startBlock;
    } else {
      fileSystem.addFreeBlock(freeBlock);
    }
  });
  return fileSystem.checksum();
}

void main() async {
  var encodedDiskMap = (await File("input.txt").readAsLines())[0];
  print(compact(decodeDiskMap(encodedDiskMap)));
  print(compact2(decodeDiskMap(encodedDiskMap)));
}

FileSystem decodeDiskMap(String encodedDiskMap) {
  var block = 0;
  var id = 0;
  var isFile = true;
  var fileSystem = FileSystem();
  encodedDiskMap.split('').forEach((char) {
    var size = int.parse(char);
    if (isFile) {
      fileSystem.addFile(DiskFile(id, block, size));
      id++;
    } else {
      fileSystem.addFreeBlock(FreeBlock(block, size));
    }
    block += size;
    isFile = !isFile;
  });
  return fileSystem;
}
