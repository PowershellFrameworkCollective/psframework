using PSFramework.Parameter;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Caching
{
    /// <summary>
    /// A type of cache intended for concurrent access, but solely within memory.
    /// </summary>
    public class CacheMemoryConcurrent : CacheBase
    {
        internal object _WriteLock = 42;

        #region Constructors
        /// <summary>
        /// Creates a default threadsafe memory-only cache.
        /// </summary>
        public CacheMemoryConcurrent()
            :base()
        {

        }

        /// <summary>
        /// Creates a configured threadsafe memory-only cache.
        /// </summary>
        /// <param name="MaxItems">The maximum number of items the cache may contain</param>
        /// <param name="Lifetime">The maximum age a cached item may reach</param>
        public CacheMemoryConcurrent(long MaxItems, TimeSpanParameter Lifetime)
            :base()
        {
            this.MaxItems = MaxItems;
            this.Lifetime = Lifetime;
        }
        #endregion Constructors

        #region Generic Overrides
        /// <summary>
        /// Create a hashtable containing all cache entries
        /// </summary>
        /// <returns>A non-case-sensitive hashtable containing all cache entries</returns>
        public override object Clone()
        {
            lock (_WriteLock)
            {
                return base.Clone();
            }
        }
        #endregion Generic Overrides

        #region Core Overrides
        /// <summary>
        /// Add an entry to the cache
        /// </summary>
        /// <param name="key">The key of the entry</param>
        /// <param name="value">The value of the entry</param>
        public override void Add(object key, object value)
        {
            lock (_WriteLock)
            {
                base.Add(key, new CachedData(this, key, value));
            }
            Drain();
        }
        /// <summary>
        /// Remove an entry from the cache
        /// </summary>
        /// <param name="key">The key of the entry to remove</param>
        public override void Remove(object key)
        {
            lock (_WriteLock)
            {
                if (!base.ContainsKeyInt(key))
                    return;
                
                ((CachedData)base[key]).Dispose();
                base.RemoveInt(key);
            }
        }

        /// <summary>
        /// Internal tool to remove an entry from the cache
        /// </summary>
        /// <param name="Key">The key of the entry to remove</param>
        internal new void RemoveInt(object Key)
        {
            if (ContainsKey(Key))
                base.RemoveInt(Key);
        }

        /// <summary>
        /// Verifies whether the key exists in the cache.
        /// Expired entries are not considered.
        /// </summary>
        /// <param name="key">The key to check</param>
        /// <returns>Whether the key is in the cache</returns>
        public override bool ContainsKey(object key)
        {
            // The new ContainsKey operation comes in two steps
            // Thread-Safety requires a lock so nobody kills the entry inbetween the check and the expiration test
            lock (_WriteLock)
            {
                return base.ContainsKey(key);
            }
        }

        /// <summary>
        /// Read or write an entry in the cache
        /// </summary>
        /// <param name="key">The key of the entry</param>
        /// <returns>The value matching the key</returns>
        public override object this[object key]
        {
            get
            {
                object temp = base[key];
                if (temp == null)
                {
                    if (Collector == null)
                        return null;
                    try
                    {
                        CollectorCode.InvokeEx(false, key, key, this, false, true, Collector);
                        temp = base[key];
                        if (temp == null)
                            return null;
                        return ((CachedData)temp).Value;
                    }
                    catch (RuntimeException rex)
                    {
                        throw rex.ErrorRecord.Exception;
                    }
                    catch (Exception ex)
                    {
                        throw ex;
                    }
                }
                return ((CachedData)temp).Value;
            }
            //set => base[key] = value;
            set
            {
                lock (_WriteLock)
                {
                    if (base.ContainsKey(key))
                        ((CachedData)base[key]).Value = value;
                    else
                        base[key] = new CachedData(this, key, value);
                }
                Drain();
            }
        }
        #endregion Core Overrides
    }
}
