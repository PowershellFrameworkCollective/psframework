using PSFramework.Utility;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Timers;
using System.Threading.Tasks;

namespace PSFramework.Temp
{
    /// <summary>
    /// Container unit for temporary items.
    /// Ensures keeping track of and disposing any and all temporary items.
    /// </summary>
    public class TempItemContainer
    {
        /// <summary>
        /// List of all temporary items registered
        /// </summary>
        public List<TempItem> Items { get; set; } = new List<TempItem>();

        /// <summary>
        /// The list of temp item providers
        /// </summary>
        public Dictionary<string, TempItemProvider> Providers { get; set; } = new Dictionary<string, TempItemProvider>(StringComparer.OrdinalIgnoreCase);

        /// <summary>
        /// Timer that tries to maintain the schedule on temp items with a timeout.
        /// </summary>
        private Timer _Timer;

        /// <summary>
        /// Create a default container for temporary items
        /// </summary>
        public TempItemContainer()
        {

        }

        /// <summary>
        /// Remove all temp items, cleaning up behind yourself
        /// </summary>
        public void Clear()
        {
            foreach (TempItem item in Items.ToArray())
                item.Delete();
        }

        /// <summary>
        /// Remove all temp items that are bveyond their timeout
        /// </summary>
        public void ClearExpired()
        {
            List<TempItem> toClear = Items.Where(o => o.Timeout != null && o.Timeout < DateTime.Now).ToList();
            foreach (TempItem item in toClear)
                item.Delete();
        }

        /// <summary>
        /// Starts the scheduler to handle TempItems that have a timeout
        /// </summary>
        public void StartTimer()
        {
            _Timer = new Timer();
            _Timer.Interval = 60000;
            _Timer.Elapsed += ClearExpiredEvent;
            _Timer.Enabled = true;
        }

        /// <summary>
        /// Stops the scheduler to handle TempItems that have a timeout
        /// </summary>
        public void StopTimer()
        {
            _Timer.Enabled = false;
        }

        private static void ClearExpiredEvent(Object source, ElapsedEventArgs e)
        {
            ((TempItemContainer)source).ClearExpired();
        }

        /// <summary>
        /// Returns all temp items that meet the module and name condition (using wildcard evaluation)
        /// </summary>
        /// <param name="Module">Module to search by</param>
        /// <param name="Name">Name of the TempItem to search by</param>
        /// <returns>A list of TempItems matching the search patterns.</returns>
        public List<TempItem> Get(string Module, string Name)
        {
            return Items.Where(o => UtilityHost.IsLike(o.Module, Module) && UtilityHost.IsLike(o.Name, Name)).ToList();
        }
    }
}
