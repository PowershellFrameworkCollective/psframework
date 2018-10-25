using System;
using System.Collections.Concurrent;

namespace PSFramework.Utility
{
    /// <summary>
    /// A dynamic content object that implements a list
    /// </summary>
    public class DynamicContentList : DynamicContentObject
    {
        /// <summary>
        /// The value of the dynamic content object
        /// </summary>
        public new object Value
        {
            get { return _List; }
            set
            {
                if (value == null)
                    _List = new BlockingCollection<object>();
                else if ((value as BlockingCollection<object>) != null)
                    _List = value as BlockingCollection<object>;
                else
                    throw new ArgumentException("Only accepts concurrent lists. Specify a null value to reset or queue to add items!");
            }
        }
        private BlockingCollection<object> _List = new BlockingCollection<object>();

        /// <summary>
        /// Creates a dynamic content object concurrent list 
        /// </summary>
        /// <param name="Name">The name of the setting</param>
        /// <param name="Value">The initial value of the object</param>
        public DynamicContentList(string Name, object Value)
            : base(Name, Value)
        {

        }

        /// <summary>
        /// How many items are currently listed
        /// </summary>
        public int Count
        {
            get { return _List.Count; }
        }

        /// <summary>
        /// Returns the current list content as array
        /// </summary>
        /// <returns>The current queue content</returns>
        public object[] ToArray()
        {
            return _List.ToArray();
        }

        /// <summary>
        /// Adds an item to the list
        /// </summary>
        /// <param name="Item">The item to add</param>
        public void Add(object Item)
        {
            _List.Add(Item);
        }

        /// <summary>
        /// Returns an object if there is anything to take from the list
        /// </summary>
        /// <returns>The next queued item</returns>
        public object Take()
        {
            object value;
            _List.TryTake(out value);
            return value;
        }

        /// <summary>
        /// Resets the stack by reestablishing an empty list.
        /// </summary>
        public void Reset()
        {
            Value = new BlockingCollection<object>();
        }
    }
}
