using PSFramework.Utility;
using System;
using System.Collections.Generic;
using System.Linq;

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
