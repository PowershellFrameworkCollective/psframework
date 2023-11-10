using PSFramework.Parameter;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Utility
{
    /// <summary>
    /// A throttle limit based on "Not Before" a certain timestamp
    /// </summary>
    public class ThrottleTime : ThrottleBase
    {
        /// <summary>
        /// The time limit: No execution before this time should occur
        /// </summary>
        public DateTime NotBefore;

        /// <summary>
        /// The parent throttle object
        /// </summary>
        public Throttle Parent;

        /// <summary>
        /// Creates a new throttle condition object, preventing the execution before the specified time
        /// </summary>
        /// <param name="notBefore">The timestamp until which we shall wait</param>
        /// <param name="parent">The throttle object</param>
        public ThrottleTime(DateTime notBefore, Throttle parent)
        {
            NotBefore = notBefore;
            Parent = parent;
        }

        /// <summary>
        /// Take a chill pill until the time limit is over
        /// </summary>
        /// <param name="Timeout">Maximum time we are willing to wait. Will error right away, if the time limit is longer.</param>
        /// <exception cref="TimeoutException">Won't return before the timeout</exception>
        public override void GetSlot(TimeSpanParameter Timeout = null)
        {
            if (Timeout != null && DateTime.Now.Add(Timeout) < NotBefore)
                throw new TimeoutException($"The timeout {Timeout} will expire before the time blocker {NotBefore} has passed!");

            System.Threading.Thread.Sleep(NotBefore - DateTime.Now);
            Reset();
        }

        /// <summary>
        /// Do nothing
        /// </summary>
        public override void Purge()
        {
            // Nothing happens here
        }

        /// <summary>
        /// Disables the limit
        /// </summary>
        public override void Reset()
        {
            NotBefore = DateTime.MinValue;
            if (null == Parent)
                return;

            KeyValuePair<Guid, ThrottleBase> key = Parent._Throttles.Where(o => o.Value == this).First();
            if (key.Key != null)
                Parent._Throttles.TryRemove(key.Key, out _);
        }
    }
}
