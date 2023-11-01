using System;
using System.Collections;
using System.Collections.Concurrent;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Runspace
{
    /// <summary>
    /// Wrapper around a concurrent queue, adding some flow control and documentation
    /// </summary>
    public class RSQueue : ConcurrentQueue<object>
    {
        /// <summary>
        /// Name of the Queue.
        /// </summary>
        public string Name;

        /// <summary>
        /// Total number of items that were ever enqueued into this queue
        /// </summary>
        public int TotalItemCount;

        /// <summary>
        /// Whether this queue has been closed. Closed queues silently ignore any further input.
        /// </summary>
        public bool Closed;

        /// <summary>
        /// Add a new item to the queue
        /// </summary>
        /// <param name="Input">The item to enqueue</param>
        public new void Enqueue(object Input)
        {
            if (Closed)
                return;

            TotalItemCount++;
            base.Enqueue(Input);
        }

        /// <summary>
        /// Add a large list of items to the queue
        /// </summary>
        /// <param name="Input">A colection of input objects.</param>
        public void EnqueueBulk(ICollection Input)
        {
            if (Closed)
                return;

            foreach (object item in Input)
            {
                TotalItemCount++;
                base.Enqueue(item);
            }
        }

        /// <summary>
        /// Return an item from the queue, or null if empty.
        /// </summary>
        /// <returns>The oldest item in the queue or null if empty.</returns>
        public object Dequeue()
        {
            object result = null;
            TryDequeue(out result);
            return result;
        }
    }
}
