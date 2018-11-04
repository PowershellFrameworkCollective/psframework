using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Localization
{
    /// <summary>
    /// An accessor, designed to make strings more accessible from within powershell script code
    /// </summary>
    public class LocalStrings : IDictionary<string, string>, IDictionary
    {
        /// <summary>
        /// The name of the module to map with this accessor
        /// </summary>
        private string _ModuleName;

        /// <summary>
        /// Helper method that qualifies names with the module
        /// </summary>
        /// <param name="Name"></param>
        /// <returns></returns>
        private string Qualify(string Name)
        {
            return String.Join(".", _ModuleName, Name);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="Key"></param>
        /// <returns></returns>
        public bool ContainsKey(string Key)
        {
            return LocalizationHost.Strings.ContainsKey(Qualify(Key));
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="Key"></param>
        /// <param name="Value"></param>
        public void Add(string Key, string Value)
        {
            throw new NotSupportedException();
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="Key"></param>
        /// <returns></returns>
        public bool Remove(string Key)
        {
            throw new NotSupportedException();
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="Key"></param>
        /// <param name="Value"></param>
        /// <returns></returns>
        public bool TryGetValue(string Key, out string Value)
        {
            Value = "";
            if (ContainsKey(Key))
            {
                Value = LocalizationHost.Strings[Qualify(Key)].Value;
                return true;
            }
            return false;
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="item"></param>
        public void Add(KeyValuePair<string, string> item)
        {
            throw new NotSupportedException();
        }

        /// <summary>
        /// 
        /// </summary>
        public void Clear()
        {
            throw new NotSupportedException();
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="item"></param>
        /// <returns></returns>
        public bool Contains(KeyValuePair<string, string> item)
        {
            throw new NotSupportedException();
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="array"></param>
        /// <param name="arrayIndex"></param>
        public void CopyTo(KeyValuePair<string, string>[] array, int arrayIndex)
        {
            throw new NotSupportedException();
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="item"></param>
        /// <returns></returns>
        public bool Remove(KeyValuePair<string, string> item)
        {
            throw new NotSupportedException();
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        public IEnumerator<KeyValuePair<string, string>> GetEnumerator()
        {
            return LocalizationHost.Strings.Values.Where(o => String.Equals(_ModuleName, o.Module, StringComparison.InvariantCultureIgnoreCase)).ToDictionary(pair => pair.Name, pair => pair.Value).GetEnumerator();
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        IEnumerator IEnumerable.GetEnumerator()
        {
            return LocalizationHost.Strings.Values.Where(o => String.Equals(_ModuleName, o.Module, StringComparison.InvariantCultureIgnoreCase)).ToDictionary(pair => pair.Name, pair => pair.Value).GetEnumerator();
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="key"></param>
        /// <returns></returns>
        public bool Contains(object key)
        {
            throw new NotSupportedException();
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="key"></param>
        /// <param name="value"></param>
        public void Add(object key, object value)
        {
            throw new NotSupportedException();
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        IDictionaryEnumerator IDictionary.GetEnumerator()
        {
            IDictionary temp = (LocalizationHost.Strings.Values.Where(
                o => String.Equals(_ModuleName, o.Module, StringComparison.InvariantCultureIgnoreCase)).ToDictionary(
                pair => pair.Name, pair => pair.Value));
            return temp.GetEnumerator();
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="key"></param>
        public void Remove(object key)
        {
            throw new NotSupportedException();
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
        public ICollection<string> Keys
        {
            get { return LocalizationHost.Strings.Values.Where(o => String.Equals(_ModuleName, o.Module, StringComparison.InvariantCultureIgnoreCase)).Select(o => o.Name).ToList(); }
        }

        /// <summary>
        /// 
        /// </summary>
        public ICollection<string> Values
        {
            get { return LocalizationHost.Strings.Values.Where(o => String.Equals(_ModuleName, o.Module, StringComparison.InvariantCultureIgnoreCase)).Select(o => o.Value).ToList(); }
        }

        /// <summary>
        /// 
        /// </summary>
        public int Count
        {
            get { return LocalizationHost.Strings.Values.Where(o => String.Equals(_ModuleName, o.Module, StringComparison.InvariantCultureIgnoreCase)).Count(); }
        }

        /// <summary>
        /// 
        /// </summary>
        public bool IsReadOnly => true;

        /// <summary>
        /// 
        /// </summary>
        ICollection IDictionary.Keys => LocalizationHost.Strings.Values.Where(o => String.Equals(_ModuleName, o.Module, StringComparison.InvariantCultureIgnoreCase)).Select(o => o.Name).ToList();

        /// <summary>
        /// 
        /// </summary>
        ICollection IDictionary.Values => LocalizationHost.Strings.Values.Where(o => String.Equals(_ModuleName, o.Module, StringComparison.InvariantCultureIgnoreCase)).Select(o => o.Value).ToList();

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
            get { return LocalizationHost.Strings[Qualify(key.ToString())].Value; }
            set { throw new NotSupportedException(); }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="key"></param>
        /// <returns></returns>
        public string this[string key]
        {
            get { return LocalizationHost.Strings[Qualify(key)].Value; }
            set { throw new NotSupportedException(); }
        }

        /// <summary>
        /// Creates a wrapper around the string collection
        /// </summary>
        /// <param name="ModuleName">The name of the module to wrap</param>
        public LocalStrings(string ModuleName)
        {
            _ModuleName = ModuleName;
        }
    }
}
