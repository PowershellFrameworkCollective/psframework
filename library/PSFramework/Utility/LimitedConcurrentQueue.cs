using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Utility
{
    /// <summary>
    /// A wrapper around a queue with a limited size. Excess items will be discarded
    /// </summary>
    public class LimitedConcurrentQueue<T> : ConcurrentQueue<T>
    {
        /// <summary>
        /// The maximum length of the limited queue
        /// </summary>
        public int Size
        {
            get { return _Size; }
            set
            {
                _Size = value;
                while (Count > _Size)
                    TryDequeue(out T temp);
            }
        }
        private int _Size = 10;

        /// <summary>
        /// Enqueues an object to the collection
        /// </summary>
        /// <param name="Item">The object to enqueue</param>
        public new void Enqueue(T Item)
        {
            base.Enqueue(Item);
            while (Count > Size)
                TryDequeue(out T temp);
        }

        /// <summary>
        /// Adds an item to the collection
        /// </summary>
        /// <param name="Item">The item to add</param>
        /// <returns>Whether adding the item succeeded</returns>
        public bool TryAdd(T Item)
        {
            try { Enqueue(Item); }
            catch { return false; }
            return true;
        }

        /// <summary>
        /// Creates a new, empty collection limited to a defaukt nax size of 10
        /// </summary>
        public LimitedConcurrentQueue()
            : this(10)
        {

        }

        /// <summary>
        /// Creates a new, empty collection limited to the specified size
        /// </summary>
        /// <param name="Size">The maximum size</param>
        public LimitedConcurrentQueue(int Size)
        {
            this.Size = Size;
        }
    }
}
