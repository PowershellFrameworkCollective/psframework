using System;
using System.Collections.Concurrent;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using PSFramework.Parameter;

namespace PSFramework.Utility
{
    /// <summary>
    /// Class implementing a throttling mechanism / watcher
    /// </summary>
    public class Throttle
    {
        /// <summary>
        /// The maximum number of slots per interval
        /// </summary>
        public int Limit;

        /// <summary>
        /// The interval over which slots are limited
        /// </summary>
        public TimeSpan Interval;

        /// <summary>
        /// The number of slots currently taken
        /// </summary>
        public int Count { get { return slots.Count; } }

        private ConcurrentQueue<DateTime> slots = new ConcurrentQueue<DateTime>();

        /// <summary>
        /// Create a new throttle object
        /// </summary>
        /// <param name="Limit">How many slots are available per interval?</param>
        /// <param name="Interval">hat is the interval over which slots are measured?</param>
        public Throttle(int Limit, TimeSpanParameter Interval)
        {
            this.Limit = Limit;
            this.Interval = Interval;
        }

        /// <summary>
        /// Obtain an execution slots from the throttle
        /// </summary>
        /// <param name="Timeout">How long are you willing to wait for a slot before giving up?</param>
        public void GetSlot(TimeSpanParameter Timeout = null)
        {
            if (slots.Count < Limit)
            {
                slots.Enqueue(DateTime.Now);
                return;
            }

            DateTime start = DateTime.Now;
            while (true)
            {
                Purge();

                if (slots.Count < Limit)
                    break;

                if (Timeout != null && start.Add(Timeout) < DateTime.Now)
                    throw new TimeoutException("Waiting too long for a slot");

                System.Threading.Thread.Sleep(250);
            }

            slots.Enqueue(DateTime.Now);
        }

        /// <summary>
        /// Clean up any expired slots
        /// </summary>
        public void Purge()
        {
            DateTime last;
            slots.TryPeek(out last);
            while (last.Add(Interval) < DateTime.Now && slots.Count > 0)
            {
                slots.TryDequeue(out last);
                slots.TryPeek(out last);
            }
        }
    }
}
