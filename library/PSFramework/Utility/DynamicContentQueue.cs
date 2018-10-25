using System;
using System.Collections.Concurrent;

namespace PSFramework.Utility
{
    /// <summary>
    /// A dynamic content object that implements a queue
    /// </summary>
    public class DynamicContentQueue : DynamicContentObject
    {
        /// <summary>
        /// The value of the dynamic content object
        /// </summary>
        public new object Value
        {
            get { return _Queue; }
            set
            {
                if (value == null)
                    _Queue = new ConcurrentQueue<object>();
                else if ((value as ConcurrentQueue<object>) != null)
                    _Queue = value as ConcurrentQueue<object>;
                else
                    throw new ArgumentException("Only accepts concurrent queues. Specify a null value to reset or queue to add items!");
            }
        }
        private ConcurrentQueue<object> _Queue = new ConcurrentQueue<object>();

        /// <summary>
        /// Creates a dynamic content object concurrent queue 
        /// </summary>
        /// <param name="Name">The name of the setting</param>
        /// <param name="Value">The initial value of the object</param>
        public DynamicContentQueue(string Name, object Value)
            : base(Name, Value)
        {
            
        }

        /// <summary>
        /// How many items are currently queued
        /// </summary>
        public int Count
        {
            get { return _Queue.Count; }
        }

        /// <summary>
        /// Returns the current queue content as array
        /// </summary>
        /// <returns>The current queue content</returns>
        public object[] ToArray()
        {
            return _Queue.ToArray();
        }

        /// <summary>
        /// Adds an item to the queue
        /// </summary>
        /// <param name="Item">The item to add</param>
        public void Enqueue(object Item)
        {
            _Queue.Enqueue(Item);
        }

        /// <summary>
        /// Returns an object if there is anything to take from the queue
        /// </summary>
        /// <returns>The next queued item</returns>
        public object Dequeue()
        {
            object value;
            _Queue.TryDequeue(out value);
            return value;
        }

        /// <summary>
        /// Resets the queue by reestablishing an empty queue.
        /// </summary>
        public void Reset()
        {
            Value = new ConcurrentQueue<object>();
        }
    }
}
