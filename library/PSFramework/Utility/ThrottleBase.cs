using PSFramework.Parameter;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Utility
{
    /// <summary>
    /// Base implementation of a throttling handler
    /// </summary>
    public abstract class ThrottleBase
    {
        /// <summary>
        /// This should only return when the next execution can happen
        /// </summary>
        /// <param name="Timeout">Maximum time to wait. Throw an exception if expires before next slot becomes available</param>
        public abstract void GetSlot(TimeSpanParameter Timeout = null);

        /// <summary>
        /// Any cleanup action to take without resetting the throttle.
        /// </summary>
        public abstract void Purge();

        /// <summary>
        /// Reset the full throttling condition to base.
        /// </summary>
        public abstract void Reset();
    }
}
