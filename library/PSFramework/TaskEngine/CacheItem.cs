using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.TaskEngine
{
    /// <summary>
    /// Runtime item handling the various meta-data for the TaskEngineCache values.
    /// </summary>
    public class CacheItem
    {
        /// <summary>
        /// The module the cache item belongs to.
        /// </summary>
        public string Module;

        /// <summary>
        /// Name of the cache item.
        /// </summary>
        public string Name;

        /// <summary>
        /// Value stored in the item
        /// </summary>
        public object Value
        {
            get
            {
                lock (_ValueLock)
                {
                    if (Expired)
                        _Value = null;
                    return _Value;
                }
            }
            set
            {
                lock (_ValueLock)
                {
                    _EverSet = true;
                    _Value = value;
                    LastSet = DateTime.Now;
                }
            }
        }
        private object _Value;
        private object _ValueLock;
        private bool _EverSet = false;

        /// <summary>
        /// Scriptblock to execute to gather data to cache
        /// </summary>
        public ScriptBlock Collector;

        /// <summary>
        /// An argument to pass to the collector scriptblock
        /// </summary>
        public object CollectorArgument;

        /// <summary>
        /// When was the value last updated
        /// </summary>
        public DateTime LastSet;

        /// <summary>
        /// How long are the values valid
        /// </summary>
        public TimeSpan Expiration;

        /// <summary>
        /// Whether the cqached data has expired
        /// </summary>
        public bool Expired
        {
            get
            {
                if (_EverSet != true)
                    return true;
                if (Expiration.TotalSeconds <= 0)
                    return false;
                return LastSet.Add(Expiration) < DateTime.Now;
            }
        }
        
        /// <summary>
        /// Create a new CacheItem
        /// </summary>
        /// <param name="Module">The module the item belongs to</param>
        /// <param name="Name">The name of the item.</param>
        public CacheItem(string Module, string Name)
        {
            this.Module = Module;
            this.Name = Name;
        }
    }
}
