using PSFramework.PSFCore;
using PSFramework.Parameter;
using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Timers;
using PSFramework.Utility;

namespace PSFramework.Caching
{
    /// <summary>
    /// Base class for different kinds of cache handlers
    /// </summary>
    public abstract class CacheBase : Hashtable, IDisposable
    {
        /// <summary>
        /// The code used to process the actual collector-code if provided in a cache.
        /// </summary>
        public static PsfScriptBlock CollectorCode
        {
            get
            {
                return _CollectorCode;
            }
            set
            {
                if (_CollectorCode == null)
                    _CollectorCode = value;
            }
        }
        private static PsfScriptBlock _CollectorCode;

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
        public TimeSpanParameter Lifetime
        {
            get => _Lifetime;
            set
            {
                if (value == null)
                    StopCleanup();
                else if (value.Value.TotalSeconds < 1)
                    StopCleanup();
                else
                    StartCleanup();
                _Lifetime = value;
            }
        }
        private TimeSpan _Lifetime;

        /// <summary>
        /// Returns the defined lifetime of cached items.
        /// Necessary because of the hashtable handling in PowerShell preventing access to properties.
        /// </summary>
        /// <returns>The Lifetime</returns>
        public TimeSpan GetLifetime()
        {
            return Lifetime.Value;
        }
        /// <summary>
        /// Set the lifetime of cached items.
        /// Necessary because of the hashtable handling in PowerShell preventing access to properties.
        /// </summary>
        /// <param name="Lifetime">How long items will remain in the cache</param>
        public void SetLifetime(TimeSpanParameter Lifetime)
        {
            this.Lifetime = Lifetime;
        }

        /// <summary>
        /// Maximum number of items to store in the cache
        /// </summary>
        public long MaxItems;
        /// <summary>
        /// Returns the maximum number of items in the cache.
        /// Necessary because of the hashtable handling in PowerShell preventing access to properties.
        /// </summary>
        /// <returns>The maximum number of items in the cache.</returns>
        public long GetMaxItems()
        {
            return MaxItems;
        }
        /// <summary>
        /// Defines the maximum number of items allowed in the cache.
        /// Necessary because of the hashtable handling in PowerShell preventing access to properties.
        /// </summary>
        /// <param name="MaxItems">The maximum number of items allowed in the cache. 0 or less disables the limit.</param>
        public void SetMaxItems(long MaxItems)
        {
            this.MaxItems = MaxItems;
        }

        /// <summary>
        /// Whether expired / surplus data entries should be disposed if implementing IDisposable
        /// </summary>
        public bool TryDispose;
        /// <summary>
        /// Returns whether expired items get explicitly disposed.
        /// Necessary because of the hashtable handling in PowerShell preventing access to properties.
        /// </summary>
        /// <returns>Whether expired items get explicitly disposed.</returns>
        public bool GetTryDispose()
        {
            return TryDispose;
        }
        /// <summary>
        /// Define whether expired items get explicitly disposed.
        /// Necessary because of the hashtable handling in PowerShell preventing access to properties.
        /// </summary>
        /// <param name="TryDispose">whether expired items get explicitly disposed</param>
        public void SetTryDispose(bool TryDispose)
        {
            this.TryDispose = TryDispose;
        }

        /// <summary>
        /// Code to collect unknown entries
        /// </summary>
        public PsfScriptBlock Collector;
        /// <summary>
        /// Returns the collection code used to gather unknown entries.
        /// Necessary because of the hashtable handling in PowerShell preventing access to properties.
        /// </summary>
        /// <returns>the collection code used to gather unknown entries.</returns>
        public PsfScriptBlock GetCollector()
        {
            return Collector;
        }
        /// <summary>
        /// Defines the collection code used to gather unknown entries.
        /// Necessary because of the hashtable handling in PowerShell preventing access to properties.
        /// </summary>
        /// <param name="Collector">the collection code used to gather unknown entries.</param>
        public void SetCollector(PsfScriptBlock Collector)
        {
            this.Collector = Collector;
        }

        /// <summary>
        /// Whether null-returns of the collector should be cached.
        /// </summary>
        public bool CacheNull;
        /// <summary>
        /// Returns whether null-returns of the collector should be cached.
        /// Necessary because of the hashtable handling in PowerShell preventing access to properties.
        /// </summary>
        /// <returns>whether null-returns of the collector should be cached.</returns>
        public bool GetCacheNull()
        {
            return CacheNull;
        }
        /// <summary>
        /// Defines whether null-returns of the collector should be cached.
        /// Necessary because of the hashtable handling in PowerShell preventing access to properties.
        /// </summary>
        /// <param name="CacheNull">whether null-returns of the collector should be cached.</param>
        public void SetCacheNull(bool CacheNull)
        {
            this.CacheNull = CacheNull;
        }


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
                CachedData[] tempData = new CachedData[base.Values.Count];
                base.Values.CopyTo(tempData, 0);
                
                foreach (CachedData entry in tempData)
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
