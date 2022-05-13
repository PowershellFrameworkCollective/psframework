using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Temp
{
    /// <summary>
    /// What kind of temp item is the object?
    /// </summary>
    public enum TempItemType
    {
        /// <summary>
        /// A regular file
        /// </summary>
        File = 1,

        /// <summary>
        /// A regular folder / directory
        /// </summary>
        Directory = 2,

        /// <summary>
        /// A generic item type
        /// </summary>
        Generic = 3
    }
}
