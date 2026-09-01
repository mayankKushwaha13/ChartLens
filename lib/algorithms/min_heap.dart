class MinHeap<T> {
  final List<T> _heap = [];

  final int Function(T a, T b) compare;

  MinHeap({
    required this.compare,
  });


  int get length => _heap.length;

  bool get isEmpty => _heap.isEmpty;

  bool get isNotEmpty => _heap.isNotEmpty;


  void add(T value) {
    _heap.add(value);

    _bubbleUp(_heap.length - 1);
  }


  T removeMin() {
    if (_heap.isEmpty) {
      throw StateError('Cannot remove from an empty heap.');
    }

    if (_heap.length == 1) {
      return _heap.removeLast();
    }

    final minimum = _heap[0];

    _heap[0] = _heap.removeLast();

    _bubbleDown(0);

    return minimum;
  }


  T get minimum {
    if (_heap.isEmpty) {
      throw StateError('Cannot access minimum of an empty heap.');
    }

    return _heap[0];
  }


  void _bubbleUp(int index) {
    while (index > 0) {
      final parentIndex = (index - 1) ~/ 2;

      if (compare(
            _heap[index],
            _heap[parentIndex],
          ) >=
          0) {
        break;
      }

      _swap(index, parentIndex);

      index = parentIndex;
    }
  }

  void _bubbleDown(int index) {
    while (true) {
      final leftChild = index * 2 + 1;
      final rightChild = index * 2 + 2;

      var smallest = index;

      if (leftChild < _heap.length &&
          compare(
                _heap[leftChild],
                _heap[smallest],
              ) <
              0) {
        smallest = leftChild;
      }

      if (rightChild < _heap.length &&
          compare(
                _heap[rightChild],
                _heap[smallest],
              ) <
              0) {
        smallest = rightChild;
      }

      if (smallest == index) {
        break;
      }

      _swap(index, smallest);

      index = smallest;
    }
  }


  void _swap(int first, int second) {
    final temp = _heap[first];

    _heap[first] = _heap[second];
    _heap[second] = temp;
  }


  List<T> toSortedList() {
    final copy = MinHeap<T>(
      compare: compare,
    );

    for (final value in _heap) {
      copy.add(value);
    }

    final result = <T>[];

    while (copy.isNotEmpty) {
      result.add(copy.removeMin());
    }

    return result;
  }
}