using PSFramework.Localization;
using System;
using System.Collections;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace PSFramework.Runspace
{
    /// <summary>
    /// Manages runspace queues. Dynamically creates the queues on demand.
    /// </summary>
    public class RSQueueManager : IDictionary<string, RSQueue>, IDictionary
    {
        private ConcurrentDictionary<string, RSQueue> _Queues = new ConcurrentDictionary<string, RSQueue>(StringComparer.InvariantCultureIgnoreCase);
        private void EnsureKey(string Name)
        {
            if (_Queues.ContainsKey(Name))
                return;

            lock (this) { _Queues[Name] = new RSQueue(); }
            _Queues[Name].Name = Name;
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="Key"></param>
        /// <returns></returns>
        public bool ContainsKey(string Key)
        {
            EnsureKey(Key);
            return true;
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="Key"></param>
        /// <param name="Value"></param>
        public void Add(string Key, RSQueue Value)
        {
            _Queues[Key] = Value;
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="Key"></param>
        /// <returns></returns>
        public bool Remove(string Key)
        {
            return _Queues.TryRemove(Key, out _);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="Key"></param>
        /// <param name="Value"></param>
        /// <returns></returns>
        public bool TryGetValue(string Key, out RSQueue Value)
        {
            EnsureKey(Key);
            return _Queues.TryGetValue(Key, out Value);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="item"></param>
        public void Add(KeyValuePair<string, RSQueue> item)
        {
            _Queues[item.Key] = item.Value;
        }

        /// <summary>
        /// 
        /// </summary>
        public void Clear()
        {
            _Queues.Clear();
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="item"></param>
        /// <returns></returns>
        public bool Contains(KeyValuePair<string, RSQueue> item)
        {
            return _Queues.Contains(item);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="array"></param>
        /// <param name="arrayIndex"></param>
        public void CopyTo(KeyValuePair<string, RSQueue>[] array, int arrayIndex)
        {
            throw new NotSupportedException();
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="item"></param>
        /// <returns></returns>
        public bool Remove(KeyValuePair<string, RSQueue> item)
        {
            return _Queues.TryRemove((string)item.Key, out _);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        public IEnumerator<KeyValuePair<string, RSQueue>> GetEnumerator()
        {
            return _Queues.GetEnumerator();
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        IEnumerator IEnumerable.GetEnumerator()
        {
            return _Queues.GetEnumerator();
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="key"></param>
        /// <returns></returns>
        public bool Contains(object key)
        {
            return _Queues.ContainsKey((string)key);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="key"></param>
        /// <param name="value"></param>
        public void Add(object key, object value)
        {
            _Queues[(string)key] = (RSQueue)value;
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        IDictionaryEnumerator IDictionary.GetEnumerator()
        {
            return (IDictionaryEnumerator)_Queues.GetEnumerator();
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="key"></param>
        public void Remove(object key)
        {
            _Queues.TryRemove((string)key, out _);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="array"></param>
        /// <param name="index"></param>
        public void CopyTo(Array array, int index)
        {
            throw new NotSupportedException();
        }

        /// <summary>
        /// 
        /// </summary>
        public ICollection<string> Keys { get => _Queues.Keys; }

        /// <summary>
        /// 
        /// </summary>
        public ICollection<RSQueue> Values { get => _Queues.Values; }

        /// <summary>
        /// 
        /// </summary>
        public int Count { get => _Queues.Count; }

        /// <summary>
        /// 
        /// </summary>
        public bool IsReadOnly => false;

        /// <summary>
        /// 
        /// </summary>
        ICollection IDictionary.Keys => _Queues.Keys.ToList();

        /// <summary>
        /// 
        /// </summary>
        ICollection IDictionary.Values => _Queues.Values.ToList();

        /// <summary>
        /// 
        /// </summary>
        public bool IsFixedSize => false;

        /// <summary>
        /// 
        /// </summary>
        public object SyncRoot => throw new NotSupportedException();

        /// <summary>
        /// 
        /// </summary>
        public bool IsSynchronized => false;

        /// <summary>
        /// 
        /// </summary>
        /// <param name="key"></param>
        /// <returns></returns>
        public object this[object key]
        {
            get {
                EnsureKey((string)key);
                return _Queues[(string)key];
            }
            set { _Queues[(string)key] = (RSQueue)value; }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="key"></param>
        /// <returns></returns>
        public RSQueue this[string key]
        {
            get {
                EnsureKey(key);
                return _Queues[key];
            }
            set { _Queues[key] = value; }
        }
    }
}
