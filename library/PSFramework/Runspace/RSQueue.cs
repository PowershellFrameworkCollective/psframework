using System;
using System.Collections;
using System.Collections.Concurrent;
using System.Linq;
using System.Text;
using System.Threading;
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
        /// Maximum number of items in the queue.
        /// Trying to add more items to it will hang the call until someone else dequeues an item.
        /// </summary>
        public int MaxItemCount;

        /// <summary>
        /// Whether this queue has been closed. Closed queues silently ignore any further input.
        /// </summary>
        public bool Closed;

		/// <summary>
        /// When was the last item added to the queue?
        /// </summary>
		public DateTime LastUpdate;

        /// <summary>
        /// Add a new item to the queue
        /// </summary>
        /// <param name="Input">The item to enqueue</param>
        public new void Enqueue(object Input)
        {
            if (Closed)
                return;

            Wait();

            if (Closed)
                return;

            Interlocked.Increment(ref TotalItemCount);
            base.Enqueue(Input);
			LastUpdate = DateTime.Now;
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
                Wait();
                if (Closed)
                    return;

                Interlocked.Increment(ref TotalItemCount);
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

        /// <summary>
        /// Wait until enough items have been taken out of the Queue to accomodate more.
        /// </summary>
        private void Wait()
        {
            while (MaxItemCount > 0 && Count >= MaxItemCount)
                Thread.Sleep(200);
        }

        /// <summary>
        /// Remove all content in the queue
        /// </summary>
        public void Clear()
        {
            lock (this)
            {
                while (Count > 0)
                    Dequeue();
            }
        }

        /// <summary>
        /// Take a look without removing anything
        /// </summary>
        /// <returns>The next item without removing it from the queue</returns>
        public object Peek()
        {
            object result = null;
            TryPeek(out result);
            return result;
        }
    }
}
