import Trie "mo:base/Trie";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import List "mo:base/List";

module{
    public type StableTrieMap<K, V> = {
        var trie : Trie.Trie<K, V>;
        var _size : Nat;
        isEq : (K, K) -> Bool;
        hashFn : (K) -> Hash.Hash;
    };

    public func new<K, V>(isEq: (K, K) -> Bool, hashFn: (K) -> Hash.Hash) : StableTrieMap<K, V>{
        {
            var trie = Trie.empty<K, V>();
            var _size = 0;
            isEq;
            hashFn;
        }
    };

    public func size<K, V>(self: StableTrieMap<K, V>) : Nat{
        self._size
    };

    public func isEmpty<K, V>(self: StableTrieMap<K, V>) : Bool{
        self._size == 0
    };

    public func replace<K, V>(
        self: StableTrieMap<K, V>,
        key : K, 
        val : V
    ) : ?V {
        let keyObj = { key; hash = self.hashFn(key) };

        let (updatedMap, prevVal) = Trie.put<K,V>(self.trie, keyObj, self.isEq, val);

        self.trie := updatedMap;

        switch(prevVal){
            case (null) {self._size += 1};
            case (_) {}
        };

        prevVal
    };

    public let put = func<K, V>(
        self: StableTrieMap<K, V>, 
        key : K,
        val : V
    ) { ignore replace(self, key, val) };

    public func get<K, V>(self: StableTrieMap<K, V>, key : K) : ?V {
      let keyObj = {key; hash = self.hashFn(key)};
      Trie.find<K, V>(self.trie, keyObj, self.isEq)
    };

    public func remove<K, V>(self : StableTrieMap<K, V>, key : K) : ?V{
        let keyObj = {key; hash = self.hashFn(key)};

        let (updatedMap, prevVal) = Trie.remove<K, V>(self.trie, keyObj, self.isEq);
        self.trie := updatedMap;

        switch(prevVal){
            case (?_) {self._size -= 1};
            case (null) {}
        };

        prevVal
    };

    public func delete<K, V>(self : StableTrieMap<K, V>, key : K){
        ignore remove(self, key)
    };

    public func entries<K, V>(self : StableTrieMap<K, V>) : Iter.Iter<(K, V)> {
        object {
            var stack = ?(self.trie, null) : List.List<Trie.Trie<K, V>>;
            
            public func next() : ?(K, V) {
                switch stack {
                    case null { null };
                    case (?(trie, stack2)) {
                        switch trie {
                            case (#empty) {
                                stack := stack2;
                                next()
                            };
                            case (#leaf({keyvals = null})) {
                                stack := stack2;
                                next()
                            };
                            case (#leaf({size = c; keyvals = ?((k, v), kvs)})) {
                                stack := ?(#leaf({size=c-1; keyvals=kvs}), stack2);
                                ?(k.key, v)
                            };
                            case (#branch(br)) {
                                stack := ?(br.left, ?(br.right, stack2));
                                next()
                            };
                        }
                    }
                }
            }
        }
    };

    public func keys<K, V>(self : StableTrieMap<K, V>)  : Iter.Iter<K>{
        Iter.map<(K, V), K>(entries(self), func((key, _)){ key })
    };
    
    public func vals<K, V>(self : StableTrieMap<K, V>) : Iter.Iter<V>{
        Iter.map<(K, V), V>(entries(self), func((_, val)){ val })
    };

    public func fromEntries<K, V>(_entries : Iter.Iter<(K, V)>, isEq: (K, K) -> Bool, hashFn: (K) -> Hash.Hash) : StableTrieMap<K, V>{
        let triemap = new<K, V>(isEq, hashFn);

        for ((key, val) in _entries) {
            put<K, V>(triemap, key, val);
        };

        triemap
    };

    public func clone<K, V>(self : StableTrieMap<K, V>) : StableTrieMap<K, V>{
        fromEntries(entries(self), self.isEq, self.hashFn)
    };

    public func clear<K, V>(self : StableTrieMap<K, V>) {
        self.trie := Trie.empty<K, V>();
        self._size := 0;
    };
};