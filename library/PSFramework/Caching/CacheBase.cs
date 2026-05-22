using PSFramework.PSFCore;
using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Timers;

namespace PSFramework.Caching
{
    /// <summary>
    /// Base class for different kinds of cache handlers
    /// </summary>
    public abstract class CacheBase : Hashtable, IDisposable
    {
        /// <summary>
        /// Creates an empty cache that is not case sensitive
        /// </summary>
        public CacheBase()
            :base(StringComparer.OrdinalIgnoreCase)
        {

        }

        /// <summary>
        /// The maximum age a dataset may have before being purged.
        /// </summary>
        public TimeSpan Lifetime
        {
            get => _Lifetime;
            set
            {
                if (value == null)
                    StopCleanup();
                else if (value.TotalSeconds < 1)
                    StopCleanup();
                else
                    StartCleanup();
                _Lifetime = value;
            }
        }
        private TimeSpan _Lifetime;

        /// <summary>
        /// Maximum number of items to store in the cache
        /// </summary>
        public long MaxItems;

        /// <summary>
        /// Whether expired / surplus data entries should be disposed if implementing IDisposable
        /// </summary>
        public bool TryDispose;


        /// <summary>
        /// List of all cached values
        /// </summary>
        public override ICollection Values => base.Values.Cast<CachedData>().Where(o => !o.IsExpired).Select(o => o.Value).ToArray();
        /// <summary>
        /// List of all cached keys
        /// </summary>
        public override ICollection Keys => base.Values.Cast<CachedData>().Where(o => !o.IsExpired).Select(o => o.Key).ToArray();

        /// <summary>
        /// Verifies whether the key exists in the cache.
        /// Expired entries are not considered.
        /// </summary>
        /// <param name="key">The key to check</param>
        /// <returns>Whether the key is in the cache</returns>
        public override bool ContainsKey(object key)
        {
            if (!base.ContainsKey(key))
                return false;
            return ((CachedData)base[key]).IsExpired;
        }
        /// <summary>
        /// Verifies whether the key exists in the cache.
        /// Expired entries are not considered.
        /// </summary>
        /// <param name="key">The key to check</param>
        /// <returns>Whether the key is in the cache</returns>
        public override bool Contains(object key)
        {
            return ContainsKey(key);
        }
        /// <summary>
        /// The number of non-expired items in the cache
        /// </summary>
        public override int Count
        {
            get { return base.Count - base.Values.Cast<CachedData>().Where(o => o.IsExpired).Count(); }
        }
        /// <summary>
        /// Count of items including expired items
        /// </summary>
        internal int ActualCount => base.Count;
        /// <summary>
        /// Create a hashtable containing all cache entries
        /// </summary>
        /// <returns>A non-case-sensitive hashtable containing all cache entries</returns>
        public override object Clone()
        {
            Hashtable temp = new Hashtable(StringComparer.InvariantCultureIgnoreCase);
            foreach (CachedData item in base.Values.Cast<CachedData>().Where(o => !o.IsExpired))
                temp[item.Key] = item.Value;
            return temp;
        }

        /// <summary>
        /// Dynamically enumerate over the still valid values
        /// </summary>
        /// <returns></returns>
        public override IDictionaryEnumerator GetEnumerator()
        {
            return ((Hashtable)Clone()).GetEnumerator();
        }

        /// <summary>
        /// Cleanup.
        /// Should be overridden based on the particular implementation of the cache.
        /// </summary>
        public void Dispose()
        {
            StopCleanup();
        }

        /// <summary>
        /// Remove the oldest items in the cache until the MaxItems count has been reached
        /// </summary>
        internal void Drain()
        {
            if (MaxItems < 1)
                return;

            while (base.Count > MaxItems)
                Oldest.Dispose();
        }

        internal void RemoveInt(object Key)
        {
            base.Remove(Key);
        }

        #region Order
        /// <summary>
        /// Order changes need to happen in correct order
        /// </summary>
        internal object _OrderLock = 42;

        /// <summary>
        /// The oldest entry in the cache
        /// </summary>
        internal CachedData Oldest;
        /// <summary>
        /// The latest entry in the cache
        /// </summary>
        internal CachedData Newest;
        #endregion Order

        #region Lifetime Cleanup
        internal Timer _LifetimeMonitor;
        internal void StartCleanup()
        {
            _LifetimeMonitor = new Timer();
            _LifetimeMonitor.Interval = 60000;
            _LifetimeMonitor.Elapsed += (sender, args) => Clean(sender, args);
            _LifetimeMonitor.Start();
        }
        internal void StopCleanup()
        {
            if (_LifetimeMonitor == null)
                return;
            _LifetimeMonitor.Stop();
            _LifetimeMonitor.Dispose();
            _LifetimeMonitor = null;
        }
        private void Clean(object source, ElapsedEventArgs e)
        {
            try
            {
                foreach (CachedData entry in base.Values)
                    if (entry.IsExpired)
                        entry.DisposeIfExpired();
            }
            catch (Exception ex)
            {
                PSFCoreHost.WriteDebug("Timer error", source);
                PSFCoreHost.WriteDebug("Timer error", ex);
            }
        }
        #endregion Lifetime Cleanup
    }
}
